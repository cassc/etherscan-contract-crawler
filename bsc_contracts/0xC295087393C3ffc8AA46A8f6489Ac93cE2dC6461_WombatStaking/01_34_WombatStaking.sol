// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;
import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { PausableUpgradeable } from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

import { IWombatPool } from "../interfaces/wombat/IWombatPool.sol";
import { IMasterWombat } from "../interfaces/wombat/IMasterWombat.sol";
import { IVeWom } from "../interfaces/wombat/IVeWom.sol";
import { IMWom } from "../interfaces/wombat/IMWom.sol";
import { IAsset } from "../interfaces/wombat/IAsset.sol";

import "../interfaces/IMintableERC20.sol";
import "../interfaces/IPoolHelper.sol";
import "../interfaces/IBaseRewardPool.sol";
import "../interfaces/IMasterMagpie.sol";
import "../libraries/ERC20FactoryLib.sol";
import "../libraries/PoolHelperFactoryLib.sol";
import "../libraries/LogExpMath.sol";
import "../libraries/DSMath.sol";
import "../libraries/SignedSafeMath.sol";

contract WombatStaking is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;
    using DSMath for uint256;
    using SignedSafeMath for int256;

    /* ============ Structs ============ */
    
    struct Pool {
        uint256 pid;                // pid on master wombat
        address depositToken;       // token to be deposited on wombat
        address lpAddress;          // token received after deposit on wombat
        address receiptToken;       // token to receive after
        address rewarder;
        address helper;
        address depositTarget;
        bool isActive;
    }

    struct Fees {
        uint256 value;              // allocation denominated by DENOMINATOR
        address to;
        bool isMWOM;
        bool isAddress;
        bool isActive;
    }

    /* ============ State Variables ============ */

    // Addresses
    address public wom;
    address public veWom;
    address public mWom;

    address public masterWombat;
    address public masterMagpie;

    // Fees
    uint256 constant DENOMINATOR = 10000;
    uint256 public totalFee;

    //
    uint256 public lockDays;

    mapping(address => Pool) public pools;
    mapping(address => address[]) public assetToBonusRewards;  // extra rewards for alt pool

    address [] private poolTokenList; 

    Fees[] public feeInfos;

    /* ============ Events ============ */

    // Admin
    event PoolAdded(uint256 _pid, address _depositToken, address _lpAddress, address _helper, address _rewarder, address _receiptToken);
    event PoolRemoved(uint256 _pid, address _lpToken);
    event PoolHelperUpdated(address _lpToken);
    event MasterMagpieUpdated(address _oldMasterMagpie, address _newMasterMagpie);
    event MasterWombatUpdated(address _oldWombatStaking, address _newWombatStaking);
    event SetMWom(address _oldmWom, address _newmWom);
    event SetLockDays(uint256 _oldLockDays, uint256 _newLockDays);

    // Fee
    event AddFee(address _to, uint256 _value, bool _isMWOM, bool _isAddress);
    event SetFee(address _to, uint256 _value);
    event RemoveFee(address to);
    event RewardPaidTo(address _to, address _rewardToken, uint256 _feeAmount);

    // Deposit Withdraw
    event NewDeposit(
        address indexed _user,
        address indexed _depositToken,
        uint256 _depositAmount,
        address indexed _receptToken,
        uint256 _receptAmount
    );

    event NewLPDeposit(
        address indexed _user,
        address indexed _lpToken,
        uint256 _lpAmount,
        address indexed _receptToken,
        uint256 _receptAmount
    );

    event NewWithdraw(
        address indexed _user,
        address indexed _depositToken,
        uint256 _liquitity
    );

    // mWom
    event WomLocked(uint256 _amount, uint256 _lockDays, uint256 _veWomAccumulated);

    // wom
    event WomHarvested(uint256 _amount);

    /* ============ Errors ============ */

    error OnlyPoolHelper();
    error OnlyActivePool();
    error PoolOccupied();

    /* ============ Constructor ============ */

    function __WombatStaking_init(
        address _wom,
        address _veWom,
        address _masterWombat,
        address _masterMagpie
    ) public initializer {
        __Ownable_init();
        wom = _wom;
        veWom = _veWom;
        masterWombat = _masterWombat;
        masterMagpie = _masterMagpie;
        lockDays = 1461;
    }

    /* ============ Modifiers ============ */

    modifier _onlyPoolHelper(address _lpToken) {
        Pool storage poolInfo = pools[_lpToken];

        if (msg.sender != poolInfo.helper)
            revert OnlyPoolHelper();
        _;
    }

    modifier _onlyActivePool (address _lpToken) {
        Pool storage poolInfo = pools[_lpToken];

        if (!poolInfo.isActive)
            revert OnlyActivePool();
        _;
    }

    modifier _onlyActivePoolHelper(address _lpToken) {
        Pool storage poolInfo = pools[_lpToken];

        if (msg.sender != poolInfo.helper)
            revert OnlyPoolHelper();
        if (!poolInfo.isActive)
            revert OnlyActivePool();
        _;
    }

    /* ============ External Getters ============ */

    /// @notice get the number of veWom of this contract
    function accumelatedVeWom() external view returns (uint256) {
        return IERC20(veWom).balanceOf(address(this));
    }

    function getPoolTokenList() public view returns (address[] memory ) {
        return poolTokenList;
    }

    function expectedVeWomAmount(uint256 amount, uint256 _lockDays) public pure returns (uint256) {
        // veWOM = 0.026 * lockDays^0.5
        return amount.wmul(26162237992630200).wmul(LogExpMath.pow(_lockDays * 1e18, 50e16));
    }

    /* ============ External Functions ============ */

    /// @notice deposit wombat pool token in a wombat Pool
    /// @dev this function can only be called by a PoolHelper
    /// @param _lpAddress the lp token to deposit into wombat pool
    /// @param _amount the amount to deposit
    /// @param _for the user to deposit for
    /// @param _from the address to transfer from
    function deposit(
        address _lpAddress,
        uint256 _amount,
        uint256 _minimumLiquidity,
        address _for,
        address _from
    ) nonReentrant whenNotPaused _onlyActivePoolHelper(_lpAddress) external {
        // Get information of the Pool of the token
        Pool storage poolInfo = pools[_lpAddress];
        address depositToken = poolInfo.depositToken;
        IERC20(depositToken).safeTransferFrom(_from, address(this), _amount);

        IERC20(depositToken).safeApprove(poolInfo.depositTarget, _amount);
        uint256 beforeBalance = IERC20(poolInfo.lpAddress).balanceOf(address(this));
        IWombatPool(poolInfo.depositTarget).deposit(
            depositToken,
            _amount,
            _minimumLiquidity,
            address(this),
            block.timestamp,
            false
        );

        uint256 lpReceived = IERC20(poolInfo.lpAddress).balanceOf(address(this)) - beforeBalance;
        _toMasterWomAndSendReward(_lpAddress, lpReceived, true); // triggers harvest from wombat exchange
        // update variables
        IMintableERC20(poolInfo.receiptToken).mint(msg.sender, lpReceived);
        emit NewDeposit(_for, depositToken, _amount, poolInfo.receiptToken, lpReceived);
    }

    function depositLP(
        address _lpAddress,
        uint256 _lpAmount,
        address _for
    ) nonReentrant whenNotPaused _onlyActivePoolHelper(_lpAddress) external {
        // Get information of the Pool of the token
        Pool storage poolInfo = pools[_lpAddress];

        // Transfer lp to this contract and stake it to wombat
        IERC20(poolInfo.lpAddress).safeTransferFrom(_for, address(this), _lpAmount);

        _toMasterWomAndSendReward(_lpAddress, _lpAmount, true); // triggers harvest from wombat exchange
        IMintableERC20(poolInfo.receiptToken).mint(msg.sender, _lpAmount);

        emit NewLPDeposit(_for, poolInfo.lpAddress, _lpAmount, poolInfo.receiptToken, _lpAmount);
    }

    /// @notice withdraw from a wombat Pool. Note!!! pool helper has to burn receipt token!
    /// @dev Only a PoolHelper can call this function
    /// @param _lpToken the address of the wombat pool lp token
    /// @param _liquidity wombat pool liquidity
    /// @param _minAmount The minimal amount the user accepts because of slippage
    /// @param _sender the address of the user
    function withdraw(
        address _lpToken,
        uint256 _liquidity,
        uint256 _minAmount,
        address _sender
    ) nonReentrant whenNotPaused _onlyPoolHelper(_lpToken) external {
        Pool storage poolInfo = pools[_lpToken];

        IERC20(poolInfo.lpAddress).safeApprove(poolInfo.depositTarget, _liquidity);
        _toMasterWomAndSendReward(_lpToken, _liquidity, false);

        uint256 beforeWithdraw = IERC20(poolInfo.depositToken).balanceOf(address(this));
        IWombatPool(poolInfo.depositTarget).withdraw(
            poolInfo.depositToken,
            _liquidity,
            _minAmount,
            address(this),
            block.timestamp
        );

        IERC20(poolInfo.depositToken).safeTransfer(
            _sender,
            IERC20(poolInfo.depositToken).balanceOf(address(this)) - beforeWithdraw
        );

        emit NewWithdraw(_sender, poolInfo.depositToken, _liquidity);
    }

    function burnReceiptToken(address _lpToken, uint256 _amount) 
        whenNotPaused _onlyPoolHelper(_lpToken) external {
            IMintableERC20(pools[_lpToken].receiptToken).burn(msg.sender, _amount);
    }


    /// @notice harvest a Pool from Wombat
    /// @param _lpToken wombat pool lp as helper identifier
    function harvest(
        address _lpToken
    ) whenNotPaused _onlyActivePool(_lpToken) external {
        _toMasterWomAndSendReward(_lpToken, 0, true); // triggers harvest from wombat exchange
    }

    /// @notice convert WOM to mWOM
    /// @param _amount the number of WOM to convert
    /// @dev the WOM must already be in the contract
    function convertWOM(uint256 _amount) whenNotPaused external returns(uint256) {
        uint256 veWomMintedAmount = 0;
        if (_amount > 0) {
            IERC20(wom).safeApprove(veWom, _amount);
            veWomMintedAmount = IVeWom(veWom).mint(_amount, lockDays);
        }

        emit WomLocked(_amount, lockDays, veWomMintedAmount);

        return veWomMintedAmount;
    }

    /// @notice stake all the MGP balance of the contract
    function convertAllWom() whenNotPaused external {
        this.convertWOM(IERC20(wom).balanceOf(address(this)));
    }    

    /* ============ Admin Functions ============ */

    /// @notice Register a new Pool on Wombat Staking and Master Magpie
    /// @dev this function will deploy a new WombatPoolHelper, and add the Pool to the masterMagpie
    /// @param _pid the pid of the Pool on master wombat
    /// @param _depositToken the token to stake in the wombat Pool
    /// @param _lpAddress the address of the recepit token after deposit into wombat Pool. Also used for the pool identifier on WombatStaking
    /// @param _depositTarget the address to deposit for alt Pool
    /// @param _receiptName the name of the receipt Token
    /// @param _receiptSymbol the symbol of the receipt Token    
    /// @param _allocPoints the weight of the MGP allocation
    function registerPool(
        uint256 _pid,
        address _depositToken,
        address _lpAddress,
        address _depositTarget,
        string memory _receiptName,
        string memory _receiptSymbol,
        uint256 _allocPoints,
        bool _isNative
    ) external onlyOwner {
        if (pools[_lpAddress].isActive != false) {
            revert PoolOccupied();
        }
        IERC20 newToken = IERC20(
            ERC20FactoryLib.createERC20(_receiptName, _receiptSymbol)
        );
        address rewarder = IMasterMagpie(masterMagpie).createRewarder(
            address(newToken),
            address(wom)
        );
        IPoolHelper helper = IPoolHelper(
            PoolHelperFactoryLib.createWombatPoolHelper(
                _pid,
                address(newToken),
                address(_depositToken),
                address(_lpAddress),
                address(this),
                address(masterMagpie),
                address(rewarder),
                address(mWom),
                _isNative
            )
        );
        IMasterMagpie(masterMagpie).add(
            _allocPoints,
            address(newToken),
            address(rewarder),
            address(helper),
            true            
        );
        pools[_lpAddress] = Pool({
            pid: _pid,
            isActive: true,
            depositToken: _depositToken,
            lpAddress: _lpAddress,
            receiptToken: address(newToken),
            rewarder: address(rewarder),
            helper: address(helper),
            depositTarget: _depositTarget
        });
        poolTokenList.push(_depositToken);

        emit PoolAdded(_pid, _depositToken, _lpAddress, address(helper), address(rewarder), address(newToken));
    }

    /// @notice set the mWom address    
    /// @param _mWom the mWom address
    function setMWom(address _mWom) external onlyOwner {    
        address oldmWom = mWom;
        mWom = _mWom;

        emit SetMWom(oldmWom, mWom);
    }

    function setLockDays(uint256 _newLockDays) external onlyOwner {
        uint256 oldLockDays = lockDays;
        lockDays = _newLockDays;

        emit SetLockDays(oldLockDays, lockDays);
    }

    /// @notice mark the pool as inactive
    function removePool(address _lpToken) external onlyOwner {
        pools[_lpToken].isActive = false;

        emit PoolRemoved(pools[_lpToken].pid, _lpToken);
    }

    /// @notice update the pool information on wombat deposit and master magpie.
    function updatePoolHelper (
        address _lpAddress, uint256 _pid,
        address _poolHelper, address _rewarder, 
        address _depositToken, address _depositTarget,
        uint256 _allocPoint)
        external
        onlyOwner
        _onlyActivePool(_lpAddress)
    {
        Pool storage poolInfo = pools[_lpAddress];
        poolInfo.pid = _pid;
        poolInfo.helper = _poolHelper;
        poolInfo.rewarder = _rewarder;
        poolInfo.depositToken = _depositToken;
        poolInfo.depositTarget = _depositTarget;

        IMasterMagpie(masterMagpie).set(poolInfo.receiptToken, _allocPoint, _poolHelper, _rewarder, true);

        emit PoolHelperUpdated(_lpAddress);
    }

    function setMasterMagpie(address _masterMagpie) external onlyOwner {
        address oldMasterMagpie = masterMagpie;
        masterMagpie = _masterMagpie;

        emit MasterMagpieUpdated(oldMasterMagpie, masterMagpie);
    }

    function setMasterWombat(address _masterWombat) external onlyOwner {
        address oldMasterWombat = masterWombat;
        masterWombat = _masterWombat;

        emit MasterWombatUpdated(oldMasterWombat, masterWombat);
    }

    function unlockAllVeWom() external whenPaused onlyOwner  {
        IVeWom.Breeding[] memory breedings = IVeWom(veWom).getUserInfo(address(this));
        for (uint256 i = 0; i < breedings.length; i++) {
            if (breedings[i].unlockTime < block.timestamp)
                IVeWom(veWom).burn((i));
        }

        uint256 balance = IERC20(wom).balanceOf(address(this));
        IERC20(wom).safeTransfer(owner(), balance);
    }

    /**
     * @notice pause wombat staking, restricting certain operations
     */
    function pause() external nonReentrant onlyOwner {
        _pause();
    }

    /**
     * @notice unpause wombat staking, enabling certain operations
     */
    function unpause() external nonReentrant onlyOwner {
        _unpause();
    }

    /// @notice This function adds a fee to the magpie protocol
    /// @param _value the initial value for that fee
    /// @param _to the address or contract that receives the fee
    /// @param isMWOM true if the fee is sent as MWOM, otherwise it will be WOM
    /// @param _isAddress true if the receiver is an address, otherwise it's a BaseRewarder
    function addFee(
        uint256 _value,
        address _to,
        bool isMWOM,
        bool _isAddress
    ) external onlyOwner {
        feeInfos.push(
            Fees({
                value: _value,
                to: _to,
                isMWOM: isMWOM,
                isAddress: _isAddress,
                isActive: true
            })
        );
        totalFee += _value;

        emit AddFee(_to, _value, isMWOM, _isAddress);
    }

    /// @notice change the value of some fee
    /// @dev the value must be between the min and the max specified when registering the fee
    /// @dev the value must match the max fee requirements
    /// @param _index the index of the fee in the fee list
    /// @param _value the new value of the fee
    function setFee(uint256 _index, uint256 _value) external onlyOwner {
        Fees storage fee = feeInfos[_index];
        require(fee.isActive, "Cannot change an deactivated fee");
        totalFee = totalFee - fee.value + _value;
        fee.value = _value;

        emit SetFee(fee.to, _value);
    }

    /// @notice remove some fee
    /// @param _index the index of the fee in the fee list
    function removeFee(uint256 _index) external onlyOwner {
        Fees storage fee = feeInfos[_index];
        totalFee -= fee.value;
        fee.isActive = false;

        emit RemoveFee(fee.to);
    }

    /// @notice to add bonus token claim from wombat
    function addBonusRewardForAsset(address _lpToken, address _bonusToken) external onlyOwner {
        assetToBonusRewards[_lpToken].push(_bonusToken);
    }

    /* ============ Internal Functions ============ */
    function _toMasterWomAndSendReward(address _lpToken, uint256 lpAmount, bool _isStake) internal {
        Pool storage poolInfo = pools[_lpToken];

        address[] memory bonusTokens = assetToBonusRewards[_lpToken];
        uint256 bonusTokensLength = bonusTokens.length;

        uint256 womBeforeBalance = IERC20(wom).balanceOf(address(this));
        uint256[] memory beforeBalances = _rewardBeforeBalances(_lpToken);

        if(_isStake)
            _stakeToWombatMaster(_lpToken, lpAmount); // triggers harvest from wombat exchange
        else
            IMasterWombat(masterWombat).withdraw(poolInfo.pid, lpAmount); // triggers harvest from wombat exchange
        uint256 womRewards = IERC20(wom).balanceOf(address(this)) - womBeforeBalance;
        _sendRewards(wom, poolInfo.rewarder, womRewards);

        for (uint256 i; i < bonusTokensLength; i++) {
            uint256 bonusBalanceDiff = IERC20(bonusTokens[i]).balanceOf(address(this)) - beforeBalances[i];
            if (bonusBalanceDiff > 0) {
                _sendRewards(bonusTokens[i], poolInfo.rewarder, bonusBalanceDiff);
            }
        }

        emit WomHarvested(womRewards);

    }

    function _rewardBeforeBalances(address _lpToken) internal view returns(uint256[] memory beforeBalances) {
        address[] memory bonusTokens = assetToBonusRewards[_lpToken];
        uint256 bonusTokensLength = bonusTokens.length;
        beforeBalances = new uint256[](bonusTokensLength);
        for (uint256 i; i < bonusTokensLength; i++) {
            beforeBalances[i] = IERC20(bonusTokens[i]).balanceOf(address(this));
        }
    }

    // triggers harvest from wombat exchange
    function _stakeToWombatMaster(address _lpToken, uint256 _lpAmount) internal {
        Pool storage poolInfo = pools[_lpToken];
        // Approve Transfer to Master Wombat for Staking
        IERC20(_lpToken).safeApprove(masterWombat, _lpAmount);
        IMasterWombat(masterWombat).deposit(poolInfo.pid, _lpAmount);
    }

    /// @notice Send rewards to the rewarders
    /// @param _rewardToken the address of the reward token to send
    /// @param _rewarder the rewarder that will get the rewards
    /// @param _amount the initial amount of rewards after harvest

    function _sendRewards(
        address _rewardToken,
        address _rewarder,
        uint256 _amount
    ) internal {
        uint256 originalRewardAmount = _amount;
        for (uint256 i = 0; i < feeInfos.length; i++) {
            Fees storage feeInfo = feeInfos[i];

            if (feeInfo.isActive) {
                address rewardToken = _rewardToken;
                uint256 feeAmount = (originalRewardAmount * feeInfo.value) / DENOMINATOR;
                _amount -= feeAmount;
                uint256 feeTosend = feeAmount;

                if (feeInfo.isMWOM && rewardToken == wom) {
                    IERC20(wom).safeApprove(mWom, feeAmount);
                    uint256 beforeBalnce = IMWom(mWom).balanceOf(address(this));
                    IMWom(mWom).convert(feeAmount);
                    rewardToken = mWom;
                    feeTosend = IMWom(mWom).balanceOf(address(this)) - beforeBalnce;
                }

                if (!feeInfo.isAddress) {
                    IERC20(rewardToken).safeApprove(feeInfo.to, 0);
                    IERC20(rewardToken).safeApprove(feeInfo.to, feeTosend);
                    IBaseRewardPool(feeInfo.to).queueNewRewards(feeTosend, rewardToken);
                } else {
                    IERC20(rewardToken).safeTransfer(feeInfo.to, feeTosend);
                    emit RewardPaidTo(feeInfo.to, rewardToken, feeTosend);
                }
            }
        }
        IERC20(_rewardToken).safeApprove(_rewarder, 0);
        IERC20(_rewardToken).safeApprove(_rewarder, _amount);
        IBaseRewardPool(_rewarder).queueNewRewards(_amount, _rewardToken);
    }
}