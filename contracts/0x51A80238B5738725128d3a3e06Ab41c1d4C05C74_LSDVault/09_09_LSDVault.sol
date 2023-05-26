// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.11;

import "communal/ReentrancyGuard.sol";
import "communal/Owned.sol";
import "communal/SafeERC20.sol";
import "communal/TransferHelper.sol";
//import "forge-std/console.sol";

/*
* LSD Vault Contract:
* This contract is responsible for holding and managing the deposited LSDs. It mints unshETH to depositors.
*/

//Access control hierarchy
//owner = multisig: used for initial setup + admin functions + unlocking timelocked functions
//admin = team eoa: used for emergency functions and low level configs
//timelock = multisig can propose unlock + 72 hr delay: used for functions that affect user funds

interface IunshETH {
    function minter_mint(address m_address, uint256 m_amount) external;
    function minter_burn_from(address b_address, uint256 b_amount) external;
    function timelock_address() external returns (address);
    function addMinter(address minter_address) external;
    function setTimelock(address _timelock_address) external;
    function removeMinter(address minter_address) external;
}

interface ILSDVault {
    function balanceInUnderlying() external view returns (uint256);
    function exit(uint256 amount) external;
    function shanghaiTime() external returns(uint256);
}

interface IDarknet {
    function checkPrice(address lsd) external view returns (uint256);
}

contract LSDVault is Owned, ReentrancyGuard {
    using SafeERC20 for IERC20;
    /*
    ============================================================================
    State Variables
    ============================================================================
    */
    // address public admin;
    uint256 public shanghaiTime = 1682007600; //timestamp for April 20, 2023 4:20:00PM UTC (~1 wk after ETH network upgrade)
    address public constant v1VaultAddress = address(0xE76Ffee8722c21b390eebe71b67D95602f58237F);
    address public unshETHAddress;
    address public unshethZapAddress;
    address public swapperAddress;
    address public admin;
    address public darknetAddress;

    address[] public supportedLSDs;
    mapping(address => uint256) public lsdIndex; //keep track of reverse mapping of supportedLSDs indices for fast lookup

    struct LSDConfig {
        uint256 targetWeightBps;
        uint256 weightCapBps;
        uint256 absoluteCapEth;
    }

    mapping(address => LSDConfig) public lsdConfigs;
    bool public useWeightCaps;
    bool public useAbsoluteCaps;
    bool public includeV1VaultAssets;
    mapping(address => bool) public isEnabled;

    uint256 public constant _TIMELOCK = 3 days;
    enum TimelockFunctions { MIGRATE, AMM, DARKNET, ZAP }

    struct TimelockProposal {
        address proposedAddress;
        uint256 unlockTime;
    }

    mapping(TimelockFunctions => TimelockProposal) public timelock;

    //Redeem fees in basis points, configurable by multisig
    uint256 public redeemFee = 0;
    uint256 public constant maxRedeemFee = 200; //max 200 basis points = 2% fee

    bool public depositsPaused;
    bool public migrated = false;
    bool public ammEnabled = false;

    bool public withdrawalsPaused = false;
    uint256 public withdrawalUnpauseTime;

    /*
    ============================================================================
    Events
    ============================================================================
    */
    event DepositPauseToggled(bool paused);
    event ShanghaiTimeUpdated(uint256 newTime);
    event UnshethAddressSet(address unshethAddress);
    event UnshethZapAddressSet(address unshethZapAddress);
    event AdminSet(address admin);

    event LSDAdded(address lsd);
    event LSDConfigSet(address lsd, LSDConfig config);
    event LSDDisabled(address lsd);
    event LSDEnabled(address lsd);

    event AbsoluteCapsToggled(bool useAbsoluteCaps);
    event WeightCapsToggled(bool useWeightCaps);
    event IncludeV1VaultAssetsToggled(bool includeV1Assets);
    event RedeemFeeUpdated(uint256 redeemFee);

    event TimelockUpdateProposed(TimelockFunctions _fn, address _newAddress, uint256 _unlockTime);
    event TimelockUpdateCanceled(TimelockFunctions _fn);
    event TimelockUpdateCompleted(TimelockFunctions _fn);

    event VdAmmDisabled(address swapper);

    event WithdrawalsPaused(uint256 withdrawalUnpauseTime);
    event WithdrawalsUnpaused();

    /*
    ============================================================================
    Constructor
    ============================================================================
    */
    constructor(address _owner, address _darknetAddress, address _unshethAddress, address[] memory _lsds) Owned(_owner){
        darknetAddress = _darknetAddress;
        unshETHAddress = _unshethAddress;
        depositsPaused = true;
        for(uint256 i=0; i < _lsds.length; i = unchkIncr(i)) {
            addLSD(_lsds[i]);
            setLSDConfigs(_lsds[i], 2500, 5000, 2500e18); //initialize with 25% target, 50% max, 2500ETH absolute max
        }
        useWeightCaps = false;
        useAbsoluteCaps = false;
        includeV1VaultAssets = false;
    }
    /*
    ============================================================================
    Function Modifiers
    ============================================================================
    */
    modifier onlyZap {
        require(msg.sender == unshethZapAddress, "Only the unsheth Zap contract may perform this action");
        _;
    }

    modifier onlyOwnerOrAdmin {
        require(msg.sender == owner || msg.sender == admin, "Only the owner or admin may perform this action");
        _;
    }

    modifier postShanghai {
        require(block.timestamp >= shanghaiTime + _TIMELOCK, "ShanghaiTime + Timelock has not passed" );
        _;
    }

    modifier onlyWhenPaused {
        require(depositsPaused, "Deposits must be paused before performing this action" );
        _;
    }

    modifier timelockUnlocked(TimelockFunctions _fn) {
        require(timelock[_fn].unlockTime != 0 && timelock[_fn].unlockTime <= block.timestamp, "Function is timelocked");
        require(timelock[_fn].proposedAddress != address(0), "Cannot set zero address");
        _;
    }

    //helper to perform lower gas unchecked increment in for loops
    function unchkIncr(uint256 i) private pure returns(uint256) {
        unchecked { return i+1; }
    }

    /*
    ============================================================================
    Setup functions
    ============================================================================
    */
    function setUnshethZap(address _unshethZapAddress) external onlyOwner {
        require(unshethZapAddress == address(0), "UnshETH zap address already set" );
        unshethZapAddress = _unshethZapAddress;
        emit UnshethZapAddressSet(unshethZapAddress);
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
        emit AdminSet(admin);
    }

    /*
    ============================================================================
    LSD configuration functions
    ============================================================================
    */

    //Workflow to add new LSD: First addLSD, then setLSDConfigs, then configure it in darknet, then enableLSD
    //New LSD is always added with zero weight and disabled
    //Deposits must be paused before configuring, and should be enabled when done

    function addLSD(address _lsd) public onlyOwner onlyWhenPaused {
        require(lsdIndex[_lsd] == 0, "Lsd has already been added"); //fyi fails on the first lsd being duplicated since it has actual index 0
        supportedLSDs.push(_lsd);
        lsdIndex[_lsd] = supportedLSDs.length-1; //reverse mapping of supportedLSDs indices
        isEnabled[_lsd] = false;
        lsdConfigs[_lsd] = LSDConfig(0, 0, 0);
        emit LSDAdded(_lsd);
    }

    function setLSDConfigs(address _lsd, uint256 _targetWeightBps, uint256 _maxWeightBps, uint256 _maxEthCap) public onlyOwner onlyWhenPaused {
        require(_targetWeightBps <= _maxWeightBps, "Cannot set target above max weight");
        require(_targetWeightBps <= 10000 && _maxWeightBps <= 10000, "Cannot set weight above 1");
        lsdConfigs[_lsd] = LSDConfig(_targetWeightBps, _maxWeightBps, _maxEthCap);
        emit LSDConfigSet(_lsd, lsdConfigs[_lsd]);
    }

    function enableLSD(address _lsd) public onlyOwner onlyWhenPaused {
        require(IDarknet(darknetAddress).checkPrice(_lsd) > 0, "Configure lsd in darknet before enabling");
        require(lsdConfigs[_lsd].targetWeightBps > 0 && lsdConfigs[_lsd].weightCapBps > 0 && lsdConfigs[_lsd].absoluteCapEth > 0, "Set weights before enabling");
        isEnabled[_lsd] = true;
        emit LSDEnabled(_lsd);
    }

    function enableAllLSDs() external onlyOwner onlyWhenPaused {
        for(uint256 i=0; i<supportedLSDs.length; i=unchkIncr(i)) {
            enableLSD(supportedLSDs[i]);
        }
    }

    //Disabling resets configs to zero, need to set before re-enabling
    function disableLSD(address _lsd) external onlyOwner onlyWhenPaused {
        lsdConfigs[_lsd] = LSDConfig(0, 0, 0);
        isEnabled[_lsd] = false;
        emit LSDDisabled(_lsd);
    }

    function toggleWeightCaps() external onlyOwner {
        useWeightCaps = !useWeightCaps;
        emit WeightCapsToggled(useWeightCaps);
    }

    function toggleAbsoluteCaps() external onlyOwner {
        useAbsoluteCaps = !useAbsoluteCaps;
        emit AbsoluteCapsToggled(useAbsoluteCaps);
    }

    function toggleV1VaultAssetsForCaps() external onlyOwner {
        includeV1VaultAssets = !includeV1VaultAssets;
        emit IncludeV1VaultAssetsToggled(includeV1VaultAssets);
    }

    function unpauseDeposits() external onlyOwner onlyWhenPaused {
        uint256 totalTargetWeightBps = 0;
        for(uint256 i=0; i < supportedLSDs.length; i = unchkIncr(i)) {
            uint256 targetWeightBps = lsdConfigs[supportedLSDs[i]].targetWeightBps;
            if(targetWeightBps > 0) {
                require(isEnabled[supportedLSDs[i]], "Need to enable LSD with non-zero target weight");
            }
            totalTargetWeightBps += targetWeightBps;
        }
        require(totalTargetWeightBps == 10000, "Total target weight should equal 1");
        depositsPaused = false;
        emit DepositPauseToggled(depositsPaused);
    }

    function isLsdEnabled(address lsd) public view returns(bool) {
        return isEnabled[lsd];
    }

    function getLsdIndex(address lsd) public view returns(uint256) {
        return lsdIndex[lsd];
    }

    //============================================================================
    //Minting unshETH
    //============================================================================

    function deposit(address lsd, uint256 amount) external onlyZap nonReentrant {
        _deposit(lsd, amount, true);
    }

    //Gas efficient function to mint unshETH while skipping cap checks
    function depositNoCapCheck(address lsd, uint256 amount) external onlyZap nonReentrant {
        _deposit(lsd, amount, false);
    }

    //takes a supported LSD and mints unshETH to the user in proportion
    //this is an internal function, only callable by the approved ETH zap contract
    function _deposit(address lsd, uint256 amount, bool checkAgainstCaps) private {
        require(depositsPaused == false, "Deposits are paused");
        require(migrated == false, "Already migrated, deposit to new vault");
        require(isEnabled[lsd], "LSD is disabled");
        if(checkAgainstCaps) {
            uint256 balance = getCombinedVaultBalance(lsd);
            if(useAbsoluteCaps) {
                require(balance + amount <= getAbsoluteCap(lsd), "Deposit exceeds absolute cap");
            }
            if(useWeightCaps) {
                require(balance + amount <= getWeightCap(lsd, amount), "Deposit exceeds weight based cap");
            }
        }
        uint256 price = getPrice(lsd);
        TransferHelper.safeTransferFrom(lsd, msg.sender, address(this), amount);
        IunshETH(unshETHAddress).minter_mint(msg.sender, price*amount/1e18);
    }

    function getEthConversionRate(address lsd) public view returns(uint256) {
        return IDarknet(darknetAddress).checkPrice(lsd);
    }

    function getPrice(address lsd) public view returns(uint256) {
        uint256 rate = getEthConversionRate(lsd);
        if(IERC20(unshETHAddress).totalSupply() == 0){
            return rate;
        }
        else {
            return 1e18* rate /stakedETHperunshETH();
        }
    }

    function stakedETHperunshETH() public view returns (uint256) {
        return 1e18*balanceInUnderlying()/IERC20(unshETHAddress).totalSupply();
    }

    function balanceInUnderlying() public view returns (uint256) {
        uint256 underlyingBalance = 0;
        for (uint256 i = 0; i < supportedLSDs.length; i = unchkIncr(i)) {
            uint256 rate = getEthConversionRate(supportedLSDs[i]);
            underlyingBalance += rate *IERC20(supportedLSDs[i]).balanceOf(address(this))/1e18;
        }
        return underlyingBalance;
    }

    function getAbsoluteCap(address lsd) public view returns(uint256) {
        if(!useAbsoluteCaps) {
            return type(uint256).max;
        }
        uint256 absoluteCap = 1e18*lsdConfigs[lsd].absoluteCapEth/getEthConversionRate(lsd);
        return absoluteCap;
    }

    function getWeightCap(address lsd, uint256 marginalDeposit) public view returns(uint256) {
        if(!useWeightCaps) {
            return type(uint256).max;
        }
        uint256 weightCapBps = lsdConfigs[lsd].weightCapBps;
        uint256 rate = getEthConversionRate(lsd);
        uint256 marginalDepositInEth = marginalDeposit*rate/1e18;
        uint256 v1VaultEthBalance = _getV1VaultEthBalance();
        uint256 totalEthBalance = balanceInUnderlying() + v1VaultEthBalance + marginalDepositInEth;
        uint256 weightCapInEth = totalEthBalance*weightCapBps/10000;
        return 1e18*weightCapInEth/rate;
    }

    function getEffectiveCap(address lsd, uint256 marginalDeposit) public view returns(uint256) {
        uint256 absoluteCap = getAbsoluteCap(lsd);
        uint256 weightCap = getWeightCap(lsd, marginalDeposit);
        if(weightCap < absoluteCap) {
            return weightCap;
        } else {
            return absoluteCap;
        }
    }

    function getTargetAmount(address lsd, uint256 marginalDeposit) public view returns(uint256) {
        uint256 targetWeightBps = lsdConfigs[lsd].targetWeightBps;
        uint256 rate = getEthConversionRate(lsd);
        uint256 marginalDepositInEth = marginalDeposit*rate/1e18;
        uint256 v1VaultEthBalance = _getV1VaultEthBalance();
        uint256 totalEthBalance = balanceInUnderlying() + v1VaultEthBalance + marginalDepositInEth;
        uint256 targetInEth = totalEthBalance* targetWeightBps /10000;
        return 1e18*targetInEth/rate;
    }

    function _getV1VaultBalance(address lsd) internal view returns(uint256) {
        uint256 v1VaultBalance = 0;
        if(includeV1VaultAssets) {
            v1VaultBalance = IERC20(lsd).balanceOf(v1VaultAddress);
        }
        return v1VaultBalance;
    }

    function _getV1VaultEthBalance() internal view returns(uint256) {
        uint256 v1VaultEthBalance = 0;
        if(includeV1VaultAssets) {
            v1VaultEthBalance = ILSDVault(v1VaultAddress).balanceInUnderlying();
        }
        return v1VaultEthBalance;
    }

    function getCombinedVaultBalance(address lsd) public view returns(uint256) {
        uint256 balance = IERC20(lsd).balanceOf(address(this));
        return balance + _getV1VaultBalance(lsd);
    }


    //============================================================================
    //Helper functions for UI / Zap / AMM
    //============================================================================
    function remainingRoomToCap(address lsd, uint256 marginalDeposit) public view returns(uint256) {
        uint256 combinedBalance = getCombinedVaultBalance(lsd);
        uint256 effectiveCap = getEffectiveCap(lsd, marginalDeposit);
        if(combinedBalance > effectiveCap) {
            return 0;
        } else {
            return (effectiveCap - combinedBalance);
        }
    }

    function remainingRoomToCapInEthTerms(address lsd, uint256 marginalDepositEth) public view returns(uint256) {
        uint256 rate = getEthConversionRate(lsd);
        uint256 marginalDeposit = 1e18*marginalDepositEth/rate;
        return remainingRoomToCap(lsd,marginalDeposit)*getEthConversionRate(lsd)/1e18;
    }

    function remainingRoomToTarget(address lsd, uint256 marginalDeposit) public view returns(uint256) {
        uint256 combinedBalance = getCombinedVaultBalance(lsd);
        uint256 target = getTargetAmount(lsd, marginalDeposit);
        if(combinedBalance > target) {
            return 0;
        } else {
            return (target - combinedBalance);
        }
    }

    function remainingRoomToTargetInEthTerms(address lsd, uint256 marginalDepositEth) public view returns(uint256) {
        uint256 rate = getEthConversionRate(lsd);
        uint256 marginalDeposit = 1e18*marginalDepositEth/rate;
        return remainingRoomToTarget(lsd,marginalDeposit)*rate/1e18;
    }

    //============================================================================
    //Redeeming unshETH
    //============================================================================
    function setRedeemFee(uint256 _redeemFee) external onlyOwner {
        require(_redeemFee <= maxRedeemFee, "Redeem fee too high");
        redeemFee = _redeemFee;
        emit RedeemFeeUpdated(redeemFee);
    }

    function exit(uint256 amount) external nonReentrant {
        require(migrated == false, "Already migrated, use new vault to exit");
        require(block.timestamp > shanghaiTime, "Cannot exit until shanghaiTime");
        require(!withdrawalsPaused || block.timestamp > withdrawalUnpauseTime, "Withdrawals are paused");
        require(IERC20(unshETHAddress).balanceOf(msg.sender) >= amount,  "Insufficient unshETH");
        uint256 shareOfUnsheth = 1e18*amount/IERC20(unshETHAddress).totalSupply();
        uint256 fee = shareOfUnsheth*redeemFee/10000; //redeem fees are 100% retained by remaining unshETH holders
        IunshETH(unshETHAddress).minter_burn_from(msg.sender, amount);
        for (uint256 i = 0; i < supportedLSDs.length; i = unchkIncr(i)) {
            uint256 lsdBalance = IERC20(supportedLSDs[i]).balanceOf(address(this));
            uint256 amountPerLsd = (shareOfUnsheth-fee)*lsdBalance/1e18;
            IERC20(supportedLSDs[i]).safeTransfer(msg.sender, amountPerLsd);
        }
    }

    //============================================================================
    //Timelock functions
    //============================================================================
    function createTimelockProposal(TimelockFunctions _fn, address _proposedAddress) public onlyOwner {
        require(_proposedAddress != address(0), "Cannot propose zero address");
        uint256 unlockTime = block.timestamp + _TIMELOCK;
        timelock[_fn] = TimelockProposal(_proposedAddress, unlockTime);
        emit TimelockUpdateProposed(_fn, _proposedAddress, unlockTime);
    }

    function cancelTimelockProposal(TimelockFunctions _fn) public onlyOwner {
        timelock[_fn] = TimelockProposal(address(0), 0);
        emit TimelockUpdateCanceled(_fn);
    }

    function _completeTimelockProposal(TimelockFunctions _fn) internal onlyOwner {
        timelock[_fn] = TimelockProposal(address(0), 0);
        emit TimelockUpdateCompleted(_fn);
    }

    function updateUnshethZapAddress() external onlyOwner timelockUnlocked(TimelockFunctions.ZAP) {
        unshethZapAddress = timelock[TimelockFunctions.ZAP].proposedAddress;
        _completeTimelockProposal(TimelockFunctions.ZAP);
    }

    function updateDarknetAddress() external onlyOwner timelockUnlocked(TimelockFunctions.DARKNET) {
        darknetAddress = timelock[TimelockFunctions.DARKNET].proposedAddress;
        _completeTimelockProposal(TimelockFunctions.DARKNET);
    }

    function migrateVault() external onlyOwner postShanghai timelockUnlocked(TimelockFunctions.MIGRATE) {
        require(IunshETH(unshETHAddress).timelock_address() == address(this), "LSDVault cannot change unshETH minter");
        address proposedVaultAddress = timelock[TimelockFunctions.MIGRATE].proposedAddress;
        for (uint256 i = 0; i < supportedLSDs.length; i = unchkIncr(i)) {
            uint256 balance = IERC20(supportedLSDs[i]).balanceOf(address(this));
            IERC20(supportedLSDs[i]).safeTransfer(proposedVaultAddress, balance);
        }
        IunshETH unshETH = IunshETH(unshETHAddress);
        unshETH.addMinter(proposedVaultAddress);
        unshETH.setTimelock(proposedVaultAddress);
        unshETH.removeMinter(address(this));
        migrated = true;
        _completeTimelockProposal(TimelockFunctions.MIGRATE);
    }

    function setVdAmm() external onlyOwner postShanghai timelockUnlocked(TimelockFunctions.AMM) {
        //revoke approvals to current swapper
        if(swapperAddress != address(0)) {
            _setApprovals(swapperAddress, 0);
        }
        //give max approvals to proposed swapper
        address proposedSwapper = timelock[TimelockFunctions.AMM].proposedAddress;
        _setApprovals(proposedSwapper, type(uint256).max);
        swapperAddress = proposedSwapper;
        ammEnabled = true;
        _completeTimelockProposal(TimelockFunctions.AMM);
    }

    function _setApprovals(address spender, uint256 limit) internal {
        for (uint256 i = 0; i < supportedLSDs.length; i = unchkIncr(i)) {
            TransferHelper.safeApprove(supportedLSDs[i], spender, limit);
        }
    }

    //============================================================================
    //Admin and emergency functions
    //============================================================================
    function updateShanghaiTime(uint256 _newTime) external onlyOwnerOrAdmin {
        require(_newTime < shanghaiTime + 4 weeks, "Cannot extend more than 4 weeks" );
        require(_newTime > block.timestamp, "Cannot set shanghaiTime in the past" );
        shanghaiTime = _newTime;
        emit ShanghaiTimeUpdated(shanghaiTime);
    }

    function pauseDeposits() external onlyOwnerOrAdmin {
        require(depositsPaused == false, "Already paused" );
        depositsPaused = true;
        emit DepositPauseToggled(depositsPaused);
    }
    
    function pauseWithdrawals(uint256 _unpauseTime) external onlyOwnerOrAdmin {
        //Max admin withdrawal pause is 1 day less than timelock (2 days), can't unpause again for 1 day after prev pause ends
        require(_unpauseTime <= block.timestamp + _TIMELOCK - 1 days, "Cannot pause withdrawals too long");
        require(block.timestamp >= withdrawalUnpauseTime + 1 days, "Need 1 day cooldown before pausing again");
        withdrawalUnpauseTime = _unpauseTime;
        withdrawalsPaused = true;
        emit WithdrawalsPaused(withdrawalUnpauseTime);
    }

    function unpauseWithdrawals() external onlyOwnerOrAdmin {
        withdrawalsPaused = false;
        emit WithdrawalsUnpaused();
    }

    function disableVdAmm() external onlyOwnerOrAdmin {
        require(swapperAddress != address(0), "Vdamm is not set");
        _setApprovals(swapperAddress, 0);
        emit VdAmmDisabled(swapperAddress);
    }

}