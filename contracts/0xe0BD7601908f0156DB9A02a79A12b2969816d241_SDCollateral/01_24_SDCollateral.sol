// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import './library/UtilLib.sol';

import '../contracts/interfaces/IPoolUtils.sol';
import '../contracts/interfaces/SDCollateral/ISDCollateral.sol';
import '../contracts/interfaces/SDCollateral/IAuction.sol';
import '../contracts/interfaces/IStaderOracle.sol';

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract SDCollateral is ISDCollateral, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    IStaderConfig public override staderConfig;
    mapping(uint8 => PoolThresholdInfo) public poolThresholdbyPoolId;
    mapping(address => uint256) public override operatorSDBalance;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _staderConfig) external initializer {
        UtilLib.checkNonZeroAddress(_admin);
        UtilLib.checkNonZeroAddress(_staderConfig);

        __AccessControl_init();
        __ReentrancyGuard_init();

        staderConfig = IStaderConfig(_staderConfig);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        emit UpdatedStaderConfig(_staderConfig);
    }

    /**
     * @param _sdAmount SD Token Amount to Deposit
     * @dev sender should approve this contract for spending SD
     */
    function depositSDAsCollateral(uint256 _sdAmount) external override {
        address operator = msg.sender;
        operatorSDBalance[operator] += _sdAmount;

        if (!IERC20(staderConfig.getStaderToken()).transferFrom(operator, address(this), _sdAmount)) {
            revert SDTransferFailed();
        }

        emit SDDeposited(operator, _sdAmount);
    }

    /// @notice for operator to withdraw their sd collateral, which is over and above withdraw threshold
    function withdraw(uint256 _requestedSD) external override {
        address operator = msg.sender;
        uint256 opSDBalance = operatorSDBalance[operator];

        if (opSDBalance < getOperatorWithdrawThreshold(operator) + _requestedSD) {
            revert InsufficientSDToWithdraw(opSDBalance);
        }
        operatorSDBalance[operator] -= _requestedSD;

        // cannot use safeERC20 as this contract is an upgradeable contract, and using safeERC20 is not upgrade-safe
        if (!IERC20(staderConfig.getStaderToken()).transfer(payable(operator), _requestedSD)) {
            revert SDTransferFailed();
        }

        emit SDWithdrawn(operator, _requestedSD);
    }

    /// @notice slashes one validator equi. SD amount
    /// @dev callable only by respective withdrawVaults
    /// @param _validatorId validator SD collateral to slash
    function slashValidatorSD(uint256 _validatorId, uint8 _poolId) external override nonReentrant {
        address operator = UtilLib.getOperatorForValidSender(_poolId, _validatorId, msg.sender, staderConfig);
        isPoolThresholdValid(_poolId);
        PoolThresholdInfo storage poolThreshold = poolThresholdbyPoolId[_poolId];
        uint256 sdToSlash = convertETHToSD(poolThreshold.minThreshold);
        slashSD(operator, sdToSlash);
    }

    /// @notice used to slash operator SD, incase of operator default
    /// @dev do provide SD approval to auction contract using `maxApproveSD()`
    /// @param _operator which operator SD collateral to slash
    /// @param _sdToSlash amount of SD to slash
    function slashSD(address _operator, uint256 _sdToSlash) internal {
        uint256 sdBalance = operatorSDBalance[_operator];
        uint256 sdSlashed = Math.min(_sdToSlash, sdBalance);
        if (sdSlashed == 0) {
            return;
        }
        operatorSDBalance[_operator] -= sdSlashed;
        IAuction(staderConfig.getAuctionContract()).createLot(sdSlashed);
        emit SDSlashed(_operator, staderConfig.getAuctionContract(), sdSlashed);
    }

    /// @notice for max approval to auction contract for spending SD tokens
    function maxApproveSD() external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        address auctionContract = staderConfig.getAuctionContract();
        UtilLib.checkNonZeroAddress(auctionContract);
        IERC20(staderConfig.getStaderToken()).approve(auctionContract, type(uint256).max);
    }

    // SETTERS
    function updateStaderConfig(address _staderConfig) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        UtilLib.checkNonZeroAddress(_staderConfig);
        if (_staderConfig == address(staderConfig)) {
            revert NoStateChange();
        }
        staderConfig = IStaderConfig(_staderConfig);
        emit UpdatedStaderConfig(_staderConfig);
    }

    function updatePoolThreshold(
        uint8 _poolId,
        uint256 _minThreshold,
        uint256 _maxThreshold,
        uint256 _withdrawThreshold,
        string memory _units
    ) external override {
        UtilLib.onlyManagerRole(msg.sender, staderConfig);
        if ((_minThreshold > _withdrawThreshold) || (_minThreshold > _maxThreshold)) {
            revert InvalidPoolLimit();
        }

        poolThresholdbyPoolId[_poolId] = PoolThresholdInfo({
            minThreshold: _minThreshold,
            maxThreshold: _maxThreshold,
            withdrawThreshold: _withdrawThreshold,
            units: _units
        });

        emit UpdatedPoolThreshold(_poolId, _minThreshold, _withdrawThreshold);
    }

    // GETTERS

    // returns sum of withdraw threshold accounting for all its(op's) validators
    function getOperatorWithdrawThreshold(address _operator) public view returns (uint256 operatorWithdrawThreshold) {
        (uint8 poolId, , uint256 validatorCount) = getOperatorInfo(_operator);
        isPoolThresholdValid(poolId);
        PoolThresholdInfo storage poolThreshold = poolThresholdbyPoolId[poolId];
        return convertETHToSD(poolThreshold.withdrawThreshold * validatorCount);
    }

    /// @notice checks if operator has enough SD collateral to onboard validators in a specific pool
    /// @param _operator node operator addr who want to onboard validators
    /// @param _poolId pool id, where operator wants to onboard validators
    /// @param _numValidator number of validators to onBoard
    function hasEnoughSDCollateral(
        address _operator,
        uint8 _poolId,
        uint256 _numValidator
    ) external view override returns (bool) {
        return (getRemainingSDToBond(_operator, _poolId, _numValidator) == 0);
    }

    /// @notice returns minimum amount of SD required to onboard _numValidators in a pool
    /// @param _poolId pool id, where operator wants to onboard validators
    /// @param _numValidator number of validators to onBoard (including already onboarded, if any)
    function getMinimumSDToBond(uint8 _poolId, uint256 _numValidator)
        public
        view
        override
        returns (uint256 _minSDToBond)
    {
        isPoolThresholdValid(_poolId);
        PoolThresholdInfo storage poolThreshold = poolThresholdbyPoolId[_poolId];

        _minSDToBond = convertETHToSD(poolThreshold.minThreshold);
        _minSDToBond *= _numValidator;
    }

    /// @notice returns remaining amount of SD required to onboard _numValidators
    /// @param _operator node operator addr who want to onboard validators
    /// @param _poolId pool id, where operator wants to onboard validators
    /// @param _numValidator number of validators to onBoard (including already onboarded, if any)
    function getRemainingSDToBond(
        address _operator,
        uint8 _poolId,
        uint256 _numValidator
    ) public view override returns (uint256) {
        uint256 sdBalance = operatorSDBalance[_operator];
        uint256 minSDToBond = getMinimumSDToBond(_poolId, _numValidator);
        return (sdBalance >= minSDToBond ? 0 : minSDToBond - sdBalance);
    }

    function getRewardEligibleSD(address _operator) external view override returns (uint256 _rewardEligibleSD) {
        (uint8 poolId, , uint256 validatorCount) = getOperatorInfo(_operator);

        isPoolThresholdValid(poolId);
        PoolThresholdInfo storage poolThreshold = poolThresholdbyPoolId[poolId];

        uint256 totalMinThreshold = validatorCount * convertETHToSD(poolThreshold.minThreshold);
        uint256 totalMaxThreshold = validatorCount * convertETHToSD(poolThreshold.maxThreshold);
        uint256 sdBalance = operatorSDBalance[_operator];
        return (sdBalance < totalMinThreshold ? 0 : Math.min(sdBalance, totalMaxThreshold));
    }

    function convertSDToETH(uint256 _sdAmount) external view override returns (uint256) {
        uint256 sdPriceInETH = IStaderOracle(staderConfig.getStaderOracle()).getSDPriceInETH();
        return (_sdAmount * sdPriceInETH) / staderConfig.getDecimals();
    }

    function convertETHToSD(uint256 _ethAmount) public view override returns (uint256) {
        uint256 sdPriceInETH = IStaderOracle(staderConfig.getStaderOracle()).getSDPriceInETH();
        return (_ethAmount * staderConfig.getDecimals()) / sdPriceInETH;
    }

    // HELPER

    function getOperatorInfo(address _operator)
        internal
        view
        returns (
            uint8 _poolId,
            uint256 _operatorId,
            uint256 _validatorCount
        )
    {
        IPoolUtils poolUtils = IPoolUtils(staderConfig.getPoolUtils());
        _poolId = poolUtils.getOperatorPoolId(_operator);
        INodeRegistry nodeRegistry = INodeRegistry(poolUtils.getNodeRegistry(_poolId));
        _operatorId = nodeRegistry.operatorIDByAddress(_operator);
        _validatorCount = poolUtils.getOperatorTotalNonTerminalKeys(
            _poolId,
            _operator,
            0,
            nodeRegistry.getOperatorTotalKeys(_operatorId)
        );
    }

    function isPoolThresholdValid(uint8 _poolId) internal view {
        if (bytes(poolThresholdbyPoolId[_poolId].units).length == 0) {
            revert InvalidPoolId();
        }
    }
}