// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "./XLT.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/IFeeDistributor.sol";
import "./interfaces/IGaugeFeeDistributor.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";

interface IXlt {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

interface ILightTeamVault {
    function claimTo(address to) external;
}

interface IExtendVotingEscrow is IVotingEscrow {
    function locked(address user) external returns (LockedBalance memory);
}

interface ILightGauge {
    function minter() external returns (address);

    function ltToken() external returns (address);

    function controller() external returns (address);

    function votingEscrow() external returns (address);

    function claimableTokens(address addr) external returns (uint256);
}

contract LightTeamVaultManager is OwnableUpgradeable {
    event SetCanWithdrawByAnyone(bool indexed value);
    event WithdrawLTRewards(address indexed to, uint256 amount);
    event WithdrawLT(address indexed operator, address indexed to, uint256 amount);
    event WithdrawStHOPE(address indexed to, uint256 amount);

    address public lightTeamVault;
    address public feeDistributor;
    address public gaugeFeeDistributor;
    address public stHopeGauge; // this is both a Gauge and a token
    address public votingEscrow;

    address public xlt;
    address public token; // LT

    uint256 public mintableXlt; // amount of XLT can be minted by Manager
    uint256 public stHopeTotalClaimed; // total claimed amount of stHOPE rewards
    uint256 public stHopeWithdrew; // the stHOPE had withrew
    uint256 public ltTotalClaimed; // total claimed amount of LT rewards
    uint256 public ltRewardsWithdrew; // the LT amount had withrew , only for the partial of rewards
    uint256 public ltWithdrew; // the LT amount had withrew , only for the partial of unlocded
    uint256 public lastEndtime; // save the last endtime of lock
    uint256 public constant WEEK = 7 * 86400;
    uint256 public constant LOCK_TIME = 208 * WEEK; // 208 weeks

    // if true, withdrawLT(to,amount) can by called by anyone
    // equivalent amount of XLT will be burn from "to"
    bool public canWithdrawByAnyone;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _owner, // muitiSig
        address _lightTeamVault,
        address _feeDistributor,
        address _gaugeFeeDistributor,
        address _stHopeGauge
    ) public initializer {
        require(_owner != address(0), "LightTeamVaultManager: invalid owner address");
        require(_lightTeamVault != address(0), "LightTeamVaultManager: invalid lightTeamVault address");
        require(_feeDistributor != address(0), "LightTeamVaultManager: invalid feeDistributor address");
        require(_gaugeFeeDistributor != address(0), "LightTeamVaultManager: invalid gaugeFeeDistributor address");
        require(_stHopeGauge != address(0), "LightTeamVaultManager: invalid stHopeGauge address");

        _transferOwnership(_owner);
        votingEscrow = ILightGauge(_stHopeGauge).votingEscrow();
        token = ILightGauge(_stHopeGauge).ltToken();
        stHopeGauge = _stHopeGauge;

        lightTeamVault = _lightTeamVault;
        feeDistributor = _feeDistributor;
        gaugeFeeDistributor = _gaugeFeeDistributor;

        IERC20 _xlt = new XLT(address(this));
        xlt = address(_xlt);
    }

    /***
     * @dev if set true, withdrawLT(to,amount) can by called by anyone
     */
    function setCanWithdrawByAnyone(bool _canWithdrawByAnyone) external onlyOwner {
        require(canWithdrawByAnyone != _canWithdrawByAnyone, "LightTeamVaultManager: wrong value to set");
        canWithdrawByAnyone = _canWithdrawByAnyone;

        emit SetCanWithdrawByAnyone(_canWithdrawByAnyone);
    }

    /***
     * @dev Claim unlocked LT token from LightTeamVault, then lock them to VoteEscrow for 4 years ,
     *      and record mintable XLT amount, it can only be called by owner every 24h
     * @return amount amount of locked
     */
    function claimUnlockedLTAndLockForVeLT() external onlyOwner returns (uint256) {
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        ILightTeamVault(lightTeamVault).claimTo(address(this));
        uint256 claimAmount = IERC20(token).balanceOf(address(this)) - balanceBefore;
        require(claimAmount > 0, "LightTeamVaultManager: insufficient balance to lock");
        mintableXlt += claimAmount;

        // lock LT to VoteEscrow,  must add Manager to whitelist of VoteEscrow first
        IExtendVotingEscrow _votingEscrow = IExtendVotingEscrow(votingEscrow);
        // approve for votingEscrow
        IERC20(token).approve(votingEscrow, claimAmount);

        uint256 endTime = block.timestamp + LOCK_TIME;
        if (_votingEscrow.locked(address(this)).amount == 0) {
            _votingEscrow.createLock(claimAmount, endTime, 0, 0, bytes(""));
        } else {
            _votingEscrow.increaseAmount(claimAmount, 0, 0, bytes(""));
            if ((endTime / WEEK) * WEEK > lastEndtime) _votingEscrow.increaseUnlockTime(endTime);
        }

        lastEndtime = (endTime / WEEK) * WEEK;

        return claimAmount;
    }

    /***
     * @dev Mint amount XLT to "to"
     * @param to Address of the receiver
     * @param amount amount of XLT
     */
    function mintXLT(address to, uint amount) external onlyOwner {
        require(mintableXlt >= amount, "LightTeamVaultManager: insufficient mintable amount");
        mintableXlt -= amount;
        IXlt(xlt).mint(to, amount);
    }

    /***
     * @dev When locked LT expired, withdraw it form VoteEscrow to Manager. can be called by anyone
     */
    function withdrawLTWhenExpired() external {
        IVotingEscrow(votingEscrow).withdraw();
    }

    /***
     * @dev after claimUnlockedLT or withdrawLTWhenExpired, lock LT to votingEscrow
     * @param amount amount of LT to lock
     * @param unlockTime end time to unlock , if the lock existed, unlockTime must be 0
     */
    function lockLT(uint amount, uint unlockTime) external onlyOwner {
        // lock LT to VoteEscrow,  must add Manager to whitelist of VoteEscrow first
        IExtendVotingEscrow _votingEscrow = IExtendVotingEscrow(votingEscrow);
        // approve for votingEscrow
        IERC20(token).approve(votingEscrow, amount);

        if (_votingEscrow.locked(address(this)).amount == 0) {
            _votingEscrow.createLock(amount, unlockTime, 0, 0, bytes(""));
        } else {
            require(unlockTime == 0, "LightTeamVaultManager: the lock existed, the unlockTime should be zero");
            _votingEscrow.increaseAmount(amount, 0, 0, bytes(""));
        }
    }

    /***
     * @dev Extend the unlock time
     * @param unlockTime
     */
    function increaseUnlockTime(uint unlockTime) external onlyOwner {
        IVotingEscrow(votingEscrow).increaseUnlockTime(unlockTime);
    }

    /***
     * @dev  Allocate voting power for changing multiple pool weights
     * @param gaugeAddress array of gaugeAddress
     * @param userWeights array of userWeight
     */
    function voteForGaugesWeights(address[] calldata gaugeAddresses, uint256[] calldata userWeights) external onlyOwner {
        require(gaugeAddresses.length < 128, "LightTeamVaultManager: length must less than 128");
        require(gaugeAddresses.length == userWeights.length, "LightTeamVaultManager: unmatched length");

        address _gaugeController = ILightGauge(stHopeGauge).controller();
        IGaugeController gaugeController = IGaugeController(_gaugeController);
        for (uint i; i < gaugeAddresses.length; ++i) {
            gaugeController.voteForGaugeWeights(gaugeAddresses[i], userWeights[i]);
        }
    }

    /***
     * @dev  Claim the stHOPE from multi Gauges to Manager, it is the benefit from voting
     * @param Gauge address of gaugeAddress
     * @return Amount amount of stHOPE claimed in the call
     */
    function claimFromGauges(address[] calldata gaugeAddresses) external {
        require(gaugeAddresses.length < 32, "LightTeamVaultManager: length must less than 32");
        for (uint i; i < gaugeAddresses.length; ++i) {
            require(gaugeAddresses[i] != address(0), "LightTeamVaultManager: wrong gauge address");
            uint256 fee = IGaugeFeeDistributor(gaugeFeeDistributor).claim(gaugeAddresses[i], address(this));
            stHopeTotalClaimed += fee;
        }
    }

    /***
     * @dev  Claim the stHOPE from feeDistributor to Manager
     * @return Amount amount of stHOPE claimed in the call
     */
    function claimFromFeeDistributor() external returns (uint256) {
        uint256 fee = IFeeDistributor(feeDistributor).claim(address(this));
        stHopeTotalClaimed += fee;
        return fee;
    }

    /***
     * @dev  Claim the LT to Manager, it is the benefit from hoding veLT
     * @return Amount of LT claimed in the call
     */
    function claimLT() external returns (uint256) {
        uint256 claimableTokens = ILightGauge(stHopeGauge).claimableTokens(address(this));
        require(claimableTokens > 0, "LightTeamVaultManager: insufficient rewards to claim");

        address _minter = ILightGauge(stHopeGauge).minter();
        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        IMinter(_minter).mint(stHopeGauge);
        uint256 claimAmount = IERC20(token).balanceOf(address(this)) - balanceBefore;
        ltTotalClaimed += claimAmount;
        return claimAmount;
    }

    /***
     * @dev  withdraw LT that comes from rewarding, if "to" is address(0), it will be withdraw to msg.sender
     * @param to the address withrwaw to
     * @param amount the amount to withrwaw
     */
    function withdrawLTRewards(address to, uint amount) external onlyOwner {
        if (to == address(0)) to = msg.sender;
        require(amount <= ltTotalClaimed - ltRewardsWithdrew, "LightTeamVaultManager: insufficient rewards to Withraw");
        ltRewardsWithdrew += amount;
        TransferHelper.doTransferOut(token, to, amount);

        emit WithdrawLTRewards(to, amount);
    }

    /***
     * @dev  withdraw LT that unlocked, if "to" is address(0), it will be withdraw to msg.sender
     * @param to the address withrwaw to
     * @param amount the amount to withrwaw
     */
    function withdrawLT(address to, uint amount) external {
        require(msg.sender == owner() || canWithdrawByAnyone, "LightTeamVaultManager: caller is not the owner");
        if (to == address(0)) to = msg.sender;
        if (msg.sender != owner()) require(msg.sender == to, "LightTeamVaultManager: invalid call");

        require(IERC20(xlt).balanceOf(to) >= amount, "LightTeamVaultManager: insufficient XLT to burn");
        IXlt(xlt).burn(to, amount);
        ltWithdrew += amount;
        TransferHelper.doTransferOut(token, to, amount);

        emit WithdrawLT(msg.sender, to, amount);
    }

    /***
     * @dev  withdraw stHLPE that comes from rewarding, if "to" is address(0), it will be withdraw to msg.sender
     * @param to the address withrwaw to
     * @param amount the amount to withrwaw
     */
    function withdrawStHOPE(address to, uint amount) external onlyOwner {
        if (to == address(0)) to = msg.sender;
        require(amount <= stHopeTotalClaimed - stHopeWithdrew, "LightTeamVaultManager: insufficient rewards to Withraw");
        stHopeWithdrew += amount;
        TransferHelper.doTransferOut(stHopeGauge, to, amount);

        emit WithdrawStHOPE(to, amount);
    }
}