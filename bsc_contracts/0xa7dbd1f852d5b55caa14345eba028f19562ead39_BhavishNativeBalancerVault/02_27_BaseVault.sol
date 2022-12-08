// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

import { IBhavishAdministrator } from "../Interface/IBhavishAdministrator.sol";
import { IBhavishPrediction } from "../Interface/IBhavishPrediction.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IVaultProtector } from "../Interface/IVaultProtector.sol";

interface IBhavishSDKImpl {
    function predictionMap(bytes32 _underlying, bytes32 _strike) external returns (address);
}

interface IBhavishPredictionImpl {
    function bhavishPredictionStorage() external returns (address storageAddr);

    function _claimable(IBhavishPrediction.Round memory _round, IBhavishPrediction.BetInfo memory _betInfo)
        external
        pure
        returns (bool);
}

interface IBhavishStorage {
    function getPredictionRound(uint256 _roundId) external returns (IBhavishPrediction.Round memory round);

    function getBetInfo(uint256 _roundId, address _userAddress)
        external
        returns (IBhavishPrediction.BetInfo memory betInfo);
}

/**
 * @title Base Vault
 */
abstract contract BaseVault is Pausable, AccessControl, ReentrancyGuard {
    using Address for address;
    using Math for uint256;
    using SafeMath for uint256;

    struct VaultDeposit {
        mapping(address => uint256) userDeposits;
        mapping(address => uint256) userLastDepositTime;
        mapping(address => uint256) userShares;
        uint256 totalDeposit;
        uint256 maxCapacity;
        uint256 shares;
    }

    struct VaultConfig {
        uint256 predictionPerc;
        uint256 minPredictionPerc;
        uint256 withdrawFeeRatio;
        uint256 performanceFeeRatio;
        uint256 previousRoundId;
        uint256 penultimateRoundId;
        uint256 lockPeriod;
        string supportedCurrency;
    }

    enum TransactionType {
        DEPOSIT,
        WITHDRAW
    }

    IBhavishAdministrator public bhavishAdmin;
    VaultDeposit public vaultDeposit;
    IBhavishPrediction.AssetPair public assetPair;
    VaultConfig public vaultConfig;
    IVaultProtector public protector;
    mapping(uint256 => bool) public claimRefundMap;

    uint256 public constant DENOMINATOR = 10000;
    uint256 public constant MAX_PERFORMANCE_FEE = 5000;
    uint256 public constant MAX_WITHDRAW_FEE = 100;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address public lossyWrapper;

    event FeeCollected(uint256 fee);
    event DepositProcessed(address indexed owner, uint256 assetAmount, uint256 shares, address provider);
    event WithdrawProcessed(address indexed owner, uint256 assetAmount, uint256 shares);
    event NewOperator(address indexed operator);
    event NewWithdrawFee(uint256 _fee);
    event NewPerformanceFee(uint256 _fee);
    event NewPredictionPerc(uint256 _perc);
    event NewMinPredictionPerc(uint256 _perc);
    event NewMaxCapacity(uint256 cap);
    event NewBhavishAdmin(IBhavishAdministrator _admin);
    event NewVaultProtector(IVaultProtector _protector);
    event NewLockPeriod(uint256 _period);

    // Implement following virtual methods

    function _performPrediction(
        uint256 _roundId,
        bool _nextPredictionUp,
        uint256 _predictAmount
    ) internal virtual;

    function _safeTransfer(address to, uint256 value) internal virtual;

    function getPredictionMarketAddr() internal virtual returns (address);

    function totalAssets() public view virtual returns (uint256);

    function performClaim(uint256[] memory _roundIds) external virtual;

    function performRefund(uint256[] calldata roundIds) external virtual;

    modifier onlyOperator(address _userAddress) {
        require(hasRole(OPERATOR_ROLE, _userAddress), "Caller Is Not Operator");
        _;
    }

    modifier validateUser(address _userAddress) {
        require(msg.sender == _userAddress, "invalid user address");
        _;
    }

    modifier validateMaxCap(uint256 _amount) {
        require(vaultDeposit.maxCapacity >= vaultDeposit.totalDeposit + _amount, "Vault reached max capacity");
        _;
    }

    modifier onlyAdmin(address _address) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _address), "Address not an admin");
        _;
    }

    constructor(
        IBhavishAdministrator _bhavishAdmin,
        string memory _supportedCurrency,
        bytes32 _underlying,
        bytes32 _strike,
        IVaultProtector _protector
    ) {
        bhavishAdmin = _bhavishAdmin;
        vaultConfig.supportedCurrency = _supportedCurrency;
        vaultConfig.predictionPerc = 300;
        vaultConfig.minPredictionPerc = 1000; // 10% of predictionPerc
        vaultConfig.withdrawFeeRatio = 0;
        vaultConfig.performanceFeeRatio = 1000;
        vaultConfig.lockPeriod = 1 days;
        assetPair = IBhavishPrediction.AssetPair(_underlying, _strike);
        protector = _protector;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {}

    function setOperator(address _operator) external onlyAdmin(msg.sender) {
        require(!address(_operator).isContract(), "Operator cannot be a contract");
        require(_operator != address(0), "Cannot be zero address");
        grantRole(OPERATOR_ROLE, _operator);

        emit NewOperator(_operator);
    }

    function _getPerformanceFeeRatio(uint256 _amount) internal view returns (uint256) {
        return (_amount * vaultConfig.performanceFeeRatio) / DENOMINATOR;
    }

    function _getWithdrawFeeRatio(uint256 _amount) internal view returns (uint256) {
        return (_amount * vaultConfig.withdrawFeeRatio) / DENOMINATOR;
    }

    function previewWithdraw(uint256 _shares, address _userAddress) public view returns (uint256, uint256) {
        // for values like 33.33%
        uint256 perc = (_shares * 100).ceilDiv(vaultDeposit.userShares[_userAddress]);
        uint256 amount = (vaultDeposit.userDeposits[_userAddress] * perc) / 100;
        uint256 redeemShares = convertToAssets(_shares);
        (, uint256 profit) = redeemShares.trySub(amount);

        // withdraw fee only from deposit
        uint256 fee = _getWithdrawFeeRatio(amount);
        // performance fee only from profits
        if (profit > 0) fee += _getPerformanceFeeRatio(profit);

        return (fee, redeemShares);
    }

    function pause() external whenNotPaused onlyAdmin(msg.sender) {
        _pause();
    }

    function unpause() external whenPaused onlyAdmin(msg.sender) {
        _unpause();
    }

    function getUserDeposits(address _userAddress) public view returns (uint256) {
        return vaultDeposit.userDeposits[_userAddress];
    }

    function getUserLastDepositTime(address _userAddress) public view returns (uint256) {
        return vaultDeposit.userLastDepositTime[_userAddress];
    }

    function getUserShares(address _userAddress) public view returns (uint256) {
        return vaultDeposit.userShares[_userAddress];
    }

    function setWithdrawFee(uint256 _fee) public onlyAdmin(msg.sender) {
        require(_fee <= MAX_WITHDRAW_FEE, "Cannot be > 1%");
        vaultConfig.withdrawFeeRatio = _fee;

        emit NewWithdrawFee(_fee);
    }

    function setPerformanceFee(uint256 _fee) public onlyAdmin(msg.sender) {
        require(_fee <= MAX_PERFORMANCE_FEE, "Cannot be > 50%");
        vaultConfig.performanceFeeRatio = _fee;

        emit NewPerformanceFee(_fee);
    }

    function setPredictionPerc(uint256 _perc) public onlyAdmin(msg.sender) {
        require(_perc <= 10000, "Cannot be 100%");
        vaultConfig.predictionPerc = _perc;

        emit NewPredictionPerc(_perc);
    }

    function setMinPredictionPerc(uint256 _perc) public onlyAdmin(msg.sender) {
        require(_perc <= 10000, "Cannot be 100%");
        vaultConfig.minPredictionPerc = _perc;

        emit NewMinPredictionPerc(_perc);
    }

    function setMaxCapacity(uint256 cap) public onlyAdmin(msg.sender) {
        vaultDeposit.maxCapacity = cap;

        emit NewMaxCapacity(cap);
    }

    function setBhavishAdmin(IBhavishAdministrator _admin) external onlyAdmin(msg.sender) {
        bhavishAdmin = _admin;

        emit NewBhavishAdmin(_admin);
    }

    function setVaultProtector(IVaultProtector _protector) external onlyAdmin(msg.sender) {
        protector = _protector;

        emit NewVaultProtector(_protector);
    }

    function getMaxCapacity() public view returns (uint256) {
        return vaultDeposit.maxCapacity;
    }

    function setLockPeriod(uint256 _period) public onlyAdmin(msg.sender) {
        require(_period >= 1 days && _period <= 7 days, "Cannot be < 1 days & > 7 days");
        vaultConfig.lockPeriod = _period;

        emit NewLockPeriod(_period);
    }

    function setLossyWrapper(address _address) external onlyAdmin(msg.sender) {
        require(_address.isContract(), "address not contract");
        lossyWrapper = _address;
    }

    function _depositToVault(
        address _user,
        uint256 _assetAmount,
        address _provider
    ) internal whenNotPaused validateMaxCap(_assetAmount) returns (uint256 shares) {
        if (address(msg.sender).isContract()) require(msg.sender == lossyWrapper, "invalid caller");
        else require(msg.sender == _user, "invalid caller");
        require(_assetAmount > 0, "Invalid Deposit Amount");
        vaultDeposit.userDeposits[_user] = _calculateAssets(vaultDeposit.userShares[msg.sender], _assetAmount);
        vaultDeposit.userLastDepositTime[_user] = block.timestamp;

        shares = convertToShares(_assetAmount);

        vaultDeposit.totalDeposit += _assetAmount;
        vaultDeposit.userDeposits[_user] += _assetAmount;

        vaultDeposit.userShares[_user] += shares;
        vaultDeposit.shares += shares;

        emit DepositProcessed(_user, _assetAmount, shares, _provider);
    }

    function convertToAssets(uint256 _shares) public view returns (uint256) {
        uint256 supply = vaultDeposit.shares;
        return (supply == 0) ? _shares : _shares.mulDiv(totalAssets(), supply, Math.Rounding.Down);
    }

    function _calculateAssets(uint256 _shares, uint256 _amount) internal view returns (uint256) {
        uint256 supply = vaultDeposit.shares;
        return
            (supply == 0 || _amount == 0)
                ? _shares
                : _shares.mulDiv(totalAssets() - _amount, supply, Math.Rounding.Down);
    }

    function convertToShares(uint256 _amount) public view returns (uint256) {
        uint256 supply = vaultDeposit.shares;
        return
            (_amount == 0 || supply == 0)
                ? _amount
                : _amount.mulDiv(supply, vaultDeposit.totalDeposit, Math.Rounding.Down);
    }

    function _withdrawFromVault(address _user, uint256 _shares) internal returns (uint256 assetAmount) {
        if (address(msg.sender).isContract()) require(msg.sender == lossyWrapper, "invalid caller");
        else require(msg.sender == _user, "invalid caller");
        require(
            vaultDeposit.userLastDepositTime[_user] + vaultConfig.lockPeriod < block.timestamp,
            "can't remove within lock period"
        );
        require(_shares <= vaultDeposit.userShares[_user], "Insufficient shares");
        (uint256 fee, uint256 amount) = previewWithdraw(_shares, _user);

        assetAmount = amount - fee;

        vaultDeposit.totalDeposit -= amount;
        vaultDeposit.userShares[_user] -= _shares;
        vaultDeposit.shares -= _shares;

        emit WithdrawProcessed(_user, assetAmount, _shares);
        if (fee > 0) {
            _transferToAdmin(fee);
            emit FeeCollected(fee);
        }
    }

    function getStorageAddr() internal returns (address storageAddr) {
        storageAddr = IBhavishPredictionImpl(getPredictionMarketAddr()).bhavishPredictionStorage();
    }

    function getPredictionRoundStatus(uint256 _roundId) public returns (IBhavishPrediction.RoundState roundStatus) {
        IBhavishPrediction.Round memory roundDetails = IBhavishStorage(getStorageAddr()).getPredictionRound(_roundId);
        roundStatus = roundDetails.roundState;
    }

    function getPredictionRound(uint256 _roundId) public returns (IBhavishPrediction.Round memory roundDetails) {
        roundDetails = IBhavishStorage(getStorageAddr()).getPredictionRound(_roundId);
    }

    function getBetInfo(uint256 _roundId) public returns (IBhavishPrediction.BetInfo memory betInfo) {
        betInfo = IBhavishStorage(getStorageAddr()).getBetInfo(_roundId, address(this));
    }

    function isClaimable(uint256 _roundId) public returns (bool _isClaimable) {
        _isClaimable = IBhavishPredictionImpl(getPredictionMarketAddr())._claimable(
            getPredictionRound(_roundId),
            getBetInfo(_roundId)
        );
    }

    function isClaimPending(uint256 _roundId) public returns (bool) {
        IBhavishPrediction.BetInfo memory betInfo = getBetInfo(_roundId);
        return betInfo.amountDispersed == 0;
    }

    function getRoundBetAmount(uint256 _roundId) public returns (uint256 _amount) {
        IBhavishPrediction.BetInfo memory betInfo = getBetInfo(_roundId);
        _amount = betInfo.upPredictAmount + betInfo.downPredictAmount;
    }

    function performClaimAndRefund() internal {
        if (isClaimPending(vaultConfig.penultimateRoundId)) {
            uint256[] memory roundIds = new uint256[](1);
            roundIds[0] = vaultConfig.penultimateRoundId;
            IBhavishPrediction.RoundState rStatus = getPredictionRoundStatus(vaultConfig.penultimateRoundId);
            if (rStatus == IBhavishPrediction.RoundState.ENDED) this.performClaim(roundIds);
            else if (rStatus == IBhavishPrediction.RoundState.CANCELLED) this.performRefund(roundIds);
        }

        if (isClaimPending(vaultConfig.previousRoundId)) {
            uint256[] memory roundIds = new uint256[](1);
            roundIds[0] = vaultConfig.previousRoundId;
            IBhavishPrediction.RoundState rStatus = getPredictionRoundStatus(vaultConfig.previousRoundId);
            if (rStatus == IBhavishPrediction.RoundState.ENDED) this.performClaim(roundIds);
            else if (rStatus == IBhavishPrediction.RoundState.CANCELLED) this.performRefund(roundIds);
        }
    }

    function performPrediction(uint256 roundId, bool nextPredictionUp) external whenNotPaused onlyOperator(msg.sender) {
        // Predict only Percentage defined from the current balance
        uint256 predictedAmount = getRoundBetAmount(roundId);
        IBhavishPrediction.Round memory round = getPredictionRound(roundId);
        uint256 toBePredictedAmount = protector.getMaxPredictAmount(
            address(this).balance,
            vaultConfig.predictionPerc,
            vaultConfig.minPredictionPerc,
            round.downPredictAmount,
            round.upPredictAmount,
            predictedAmount,
            nextPredictionUp
        );
        // this will also take crae first time prediction using when predictedAmount ==0
        if (toBePredictedAmount > 0) {
            _performPrediction(roundId, nextPredictionUp, toBePredictedAmount);
        }
        // solve for case when perform predict called more than once in a round
        if (vaultConfig.previousRoundId != roundId) {
            performClaimAndRefund();
            vaultConfig.penultimateRoundId = vaultConfig.previousRoundId;
            vaultConfig.previousRoundId = roundId;
        }
    }

    function _transferToAdmin(uint256 _fee) internal {
        _safeTransfer(address(bhavishAdmin), _fee);
    }
}