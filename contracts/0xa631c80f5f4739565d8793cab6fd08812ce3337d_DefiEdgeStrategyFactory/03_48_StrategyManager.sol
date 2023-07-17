//SPDX-License-Identifier: BSL
pragma solidity ^0.7.6;

// libraries
import "../libraries/ShareHelper.sol";
import "../libraries/OracleLibrary.sol";

// interfaces
import "../interfaces/IStrategyFactory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

contract StrategyManager is AccessControl, IStrategyManager {
    using SafeMath for uint256;

    event FeeChanged(uint256 tier);
    event FeeToChanged(address feeTo);
    event OperatorProposed(address indexed operator);
    event OperatorChanged(address indexed operator);
    event LimitChanged(uint256 limit);
    event MaxSwapLimitChanged(uint256 limit);
    event ClaimFee(uint256 managerFee, uint256 protocolFee);
    event PerformanceFeeChanged(uint256 performanceFeeRate);
    event StrategyModeUpdated(bool status); // true - private, false - public

    uint256 public constant MIN_FEE = 20e6; // minimum 20%
    uint256 public constant MIN_DEVIATION = 2e17; // minimum 20%

    IStrategyFactory public override factory;
    address public override operator;
    address public pendingOperator;
    address public override feeTo;

    // fee to take when user adds the liquidity
    uint256 public override managementFeeRate; // 1e8 is 100%

    // fees for the manager
    uint256 public override performanceFeeRate; // 1e8 is 100%

    // max number of shares to be minted
    // if set 0, allows unlimited deposits
    uint256 public override limit;

    // number of times user can perform swap in a day
    uint256 public maxAllowedSwap = 5;

    // current swap counter
    uint256 public swapCounter = 0;

    // tracks timestamp of the last swap happened
    uint256 public lastSwapTimestamp = 0;

    bool public isStrategyPrivate = false; // if strategy is private or public

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE"); // can only rebalance and swap
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE"); // can control everything
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE"); /// only can burn the liquidity

    bytes32 public constant USER_WHITELIST_ROLE = keccak256("USER_WHITELIST_ROLE"); /// user have access to strategy - mint & burn

    constructor(
        IStrategyFactory _factory,
        address _operator,
        address _feeTo,
        uint256 _managementFeeRate,
        uint256 _performanceFeeRate,
        uint256 _limit
    ) {
        require(_managementFeeRate <= MIN_FEE); // should be less than 20%
        require(_performanceFeeRate <= MIN_FEE); // should be less than 20%

        factory = _factory;
        operator = _operator;
        feeTo = _feeTo;

        managementFeeRate = _managementFeeRate;
        performanceFeeRate = _performanceFeeRate;
        limit = _limit;

        _setupRole(ADMIN_ROLE, _operator);
        _setupRole(USER_WHITELIST_ROLE, _operator);
        _setRoleAdmin(MANAGER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(USER_WHITELIST_ROLE, ADMIN_ROLE);
    }

    // Modifiers
    modifier onlyOperator() {
        require(hasRole(ADMIN_ROLE, msg.sender), "N");
        _;
    }

    // Modifiers
    modifier onlyGovernance() {
        require(msg.sender == factory.governance(), "N");
        _;
    }

    modifier onlyStrategy() {
        require(msg.sender == strategy(), "N");
        _;
    }

    function isUserWhiteListed(address _account) public view override returns (bool) {
        return isStrategyPrivate ? hasRole(USER_WHITELIST_ROLE, _account) : true;
    }

    function isAllowedToManage(address _account) public view override returns (bool) {
        return hasRole(ADMIN_ROLE, _account) || hasRole(MANAGER_ROLE, _account);
    }

    function isAllowedToBurn(address _account) public view override returns (bool) {
        return hasRole(ADMIN_ROLE, _account) || hasRole(MANAGER_ROLE, _account) || hasRole(BURNER_ROLE, _account);
    }

    function strategy() public view returns (address) {
        return factory.strategyByManager(address(this));
    }

    /**
     * @notice Changes the fee
     * @dev 1e8 is 100%
     * @param _fee Fee tier from indexes 0 to 2
     */
    function changeManagementFeeRate(uint256 _fee) public onlyOperator {
        require(_fee <= MIN_FEE); // should be less than 20%
        managementFeeRate = _fee;
        emit FeeChanged(managementFeeRate);
    }

    /**
     * @notice changes address where the operator is receiving the fee
     * @param _newFeeTo New address where fees should be received
     */
    function changeFeeTo(address _newFeeTo) external onlyOperator {
        feeTo = _newFeeTo;
        emit FeeToChanged(feeTo);
    }

    /**
     * @notice Change the operator
     * @param _operator Address of the new operator
     */
    function changeOperator(address _operator) external onlyOperator {
        require(_operator != operator);
        pendingOperator = _operator;
        emit OperatorProposed(pendingOperator);
    }

    /**
     * @notice Change the operator
     */
    function acceptOperator() external {
        require(msg.sender == pendingOperator);
        operator = pendingOperator;
        pendingOperator = address(0);
        emit OperatorChanged(operator);
    }

    /**
     * @notice Change strategy limit in terms of share
     * @param _limit Number of shares the strategy can mint, 0 means unlimited
     */
    function changeLimit(uint256 _limit) external onlyOperator {
        limit = _limit;
        emit LimitChanged(limit);
    }

    /**
     * @notice Manager can set the performance fee
     * @param _performanceFeeRate New performance fee, should not be more than 20%
     */
    function changePerformanceFeeRate(uint256 _performanceFeeRate) external onlyOperator {
        require(_performanceFeeRate <= MIN_FEE); // should be less than 20%
        performanceFeeRate = _performanceFeeRate;
        emit PerformanceFeeChanged(performanceFeeRate);
    }

    /**
     * @notice Manager can update strategy mode -  public, private
     * @param _isPrivate true - private strategy, false - public strategy
     */
    function updateStrategyMode(bool _isPrivate) external onlyOperator {
        isStrategyPrivate = _isPrivate;
        emit StrategyModeUpdated(isStrategyPrivate);
    }

    function allowedDeviation() public view override returns (uint256) {
        return factory.allowedDeviation(address(IStrategyBase(strategy()).pool()));
    }

    function allowedSwapDeviation() public view override returns (uint256) {
        return factory.allowedSwapDeviation(address(IStrategyBase(strategy()).pool()));
    }

    /**
     * @notice Track total swap performed in a day and revert if maximum swap limit reached.
     *         Can only be called by strategy contract
     */
    function increamentSwapCounter() external override onlyStrategy {
        uint256 currentDay = block.timestamp / 1 days;
        uint256 swapDay = lastSwapTimestamp / 1 days;

        if (currentDay == swapDay) {
            // last swap happened on same day
            uint256 _counter = swapCounter;

            require(maxAllowedSwap > _counter, "LR");

            lastSwapTimestamp = block.timestamp;
            swapCounter = _counter + 1;
        } else {
            // last swap happened on other day
            swapCounter = 1;
            lastSwapTimestamp = block.timestamp;
        }
    }

    /**
     * @notice Change strategy maximum swap limit for a day
     * @param _limit Maximum number of swap that can be performed in a day
     */
    function changeMaxSwapLimit(uint256 _limit) external onlyGovernance {
        maxAllowedSwap = _limit;
        emit MaxSwapLimitChanged(maxAllowedSwap);
    }
}