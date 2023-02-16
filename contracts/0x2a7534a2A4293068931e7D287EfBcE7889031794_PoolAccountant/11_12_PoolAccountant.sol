// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../dependencies/openzeppelin/contracts/utils/Context.sol";
import "../Errors.sol";
import "../interfaces/vesper/IVesperPool.sol";
import "./PoolAccountantStorage.sol";

/// @title Accountant for Vesper pools which keep records of strategies.
contract PoolAccountant is Initializable, Context, PoolAccountantStorageV2 {
    using SafeERC20 for IERC20;

    string public constant VERSION = "5.1.0";
    uint256 public constant MAX_BPS = 10_000;

    event EarningReported(
        address indexed strategy,
        uint256 profit,
        uint256 loss,
        uint256 payback,
        uint256 strategyDebt,
        uint256 poolDebt,
        uint256 creditLine
    );
    event LossReported(address indexed strategy, uint256 loss);
    event StrategyAdded(address indexed strategy, uint256 debtRatio, uint256 externalDepositFee);
    event StrategyRemoved(address indexed strategy);
    event StrategyMigrated(address indexed oldStrategy, address indexed newStrategy);
    event UpdatedExternalDepositFee(address indexed strategy, uint256 oldFee, uint256 newFee);
    event UpdatedPoolExternalDepositFee(uint256 oldFee, uint256 newFee);
    event UpdatedStrategyDebtRatio(address indexed strategy, uint256 oldDebtRatio, uint256 newDebtRatio);

    /**
     * @dev This init function meant to be called after proxy deployment.
     * @dev DO NOT CALL it with proxy deploy
     * @param pool_ Address of Vesper pool proxy
     */
    function init(address pool_) public initializer {
        require(pool_ != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        pool = pool_;
    }

    modifier onlyGovernor() {
        require(IVesperPool(pool).governor() == _msgSender(), "not-the-governor");
        _;
    }

    modifier onlyKeeper() {
        require(
            IVesperPool(pool).governor() == _msgSender() || IVesperPool(pool).isKeeper(_msgSender()),
            "not-a-keeper"
        );
        _;
    }

    modifier onlyMaintainer() {
        require(
            IVesperPool(pool).governor() == _msgSender() || IVesperPool(pool).isMaintainer(_msgSender()),
            "not-a-maintainer"
        );
        _;
    }

    modifier onlyPool() {
        require(pool == _msgSender(), "not-a-pool");
        _;
    }

    /**
     * @notice Get available credit limit of strategy. This is the amount strategy can borrow from pool
     * @dev Available credit limit is calculated based on current debt of pool and strategy, current debt limit of pool and strategy.
     * credit available = min(pool's debt limit, strategy's debt limit, max debt per rebalance)
     * when some strategy do not pay back outstanding debt, this impact credit line of other strategy if totalDebt of pool >= debtLimit of pool
     * @param strategy_ Strategy address
     */
    function availableCreditLimit(address strategy_) external view returns (uint256) {
        return _availableCreditLimit(strategy_);
    }

    /**
     * @notice Debt above current debt limit
     * @param strategy_ Address of strategy
     */
    function excessDebt(address strategy_) external view returns (uint256) {
        return _excessDebt(strategy_);
    }

    /// @notice Return strategies array
    function getStrategies() external view returns (address[] memory) {
        return strategies;
    }

    /// @notice Return withdrawQueue
    function getWithdrawQueue() external view returns (address[] memory) {
        return withdrawQueue;
    }

    /**
     * @notice Get total debt of given strategy
     * @param strategy_ Strategy address
     */
    function totalDebtOf(address strategy_) external view returns (uint256) {
        return strategy[strategy_].totalDebt;
    }

    function _availableCreditLimit(address strategy_) internal view returns (uint256) {
        if (IVesperPool(pool).stopEverything()) {
            return 0;
        }
        uint256 _totalValue = IVesperPool(pool).totalValue();
        uint256 _maxDebt = (strategy[strategy_].debtRatio * _totalValue) / MAX_BPS;
        uint256 _currentDebt = strategy[strategy_].totalDebt;
        if (_currentDebt >= _maxDebt) {
            return 0;
        }
        uint256 _poolDebtLimit = (totalDebtRatio * _totalValue) / MAX_BPS;
        if (totalDebt >= _poolDebtLimit) {
            return 0;
        }
        uint256 _available = _maxDebt - _currentDebt;
        _available = _min(_min(IVesperPool(pool).tokensHere(), _available), _poolDebtLimit - totalDebt);
        return _available;
    }

    function _excessDebt(address strategy_) internal view returns (uint256) {
        uint256 _currentDebt = strategy[strategy_].totalDebt;
        if (IVesperPool(pool).stopEverything()) {
            return _currentDebt;
        }
        uint256 _maxDebt = (strategy[strategy_].debtRatio * IVesperPool(pool).totalValue()) / MAX_BPS;
        return _currentDebt > _maxDebt ? (_currentDebt - _maxDebt) : 0;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Recalculate pool external deposit fee.
    /// @dev As it uses state variables for calculation, make sure to call it only after updating state variables.
    function _recalculatePoolExternalDepositFee() internal {
        uint256 _len = strategies.length;
        uint256 _externalDepositFee;

        // calculate poolExternalDepositFee and weightedFee for each strategy
        if (totalDebtRatio > 0) {
            for (uint256 i; i < _len; i++) {
                _externalDepositFee +=
                    (strategy[strategies[i]].externalDepositFee * strategy[strategies[i]].debtRatio) /
                    totalDebtRatio;
            }
        }

        // Update externalDepositFee and emit event
        emit UpdatedPoolExternalDepositFee(externalDepositFee, externalDepositFee = _externalDepositFee);
    }

    /**
     * @dev When strategy report loss, its debtRatio decreases to get fund back quickly.
     * Reduction is debt ratio is reduction in credit limit
     */
    function _reportLoss(address strategy_, uint256 loss_) internal {
        require(strategy[strategy_].totalDebt >= loss_, Errors.LOSS_TOO_HIGH);
        strategy[strategy_].totalLoss += loss_;
        strategy[strategy_].totalDebt -= loss_;
        totalDebt -= loss_;
        uint256 _deltaDebtRatio = _min(
            (loss_ * MAX_BPS) / IVesperPool(pool).totalValue(),
            strategy[strategy_].debtRatio
        );
        strategy[strategy_].debtRatio -= _deltaDebtRatio;
        totalDebtRatio -= _deltaDebtRatio;
    }

    /************************************************************************************************
     *                                     Authorized function                                      *
     ***********************************************************************************************/

    ////////////////////////////// Only Governor //////////////////////////////

    /**
     * @notice Add strategy. Once strategy is added it can call rebalance and
     * borrow fund from pool and invest that fund in provider/lender.
     * @dev Recalculate pool level external deposit fee after all state variables are updated.
     * @param strategy_ Strategy address
     * @param debtRatio_ Pool fund allocation to this strategy
     * @param externalDepositFee_ External deposit fee of strategy
     */
    function addStrategy(address strategy_, uint256 debtRatio_, uint256 externalDepositFee_) public onlyGovernor {
        require(strategy_ != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        require(!strategy[strategy_].active, Errors.STRATEGY_IS_ACTIVE);
        totalDebtRatio = totalDebtRatio + debtRatio_;
        require(totalDebtRatio <= MAX_BPS, Errors.DEBT_RATIO_LIMIT_REACHED);
        require(externalDepositFee_ <= MAX_BPS, Errors.FEE_LIMIT_REACHED);
        StrategyConfig memory newStrategy = StrategyConfig({
            active: true,
            interestFee: 0, // Obsolete
            debtRate: 0, // Obsolete
            lastRebalance: block.timestamp,
            totalDebt: 0,
            totalLoss: 0,
            totalProfit: 0,
            debtRatio: debtRatio_,
            externalDepositFee: externalDepositFee_
        });
        strategy[strategy_] = newStrategy;
        strategies.push(strategy_);
        withdrawQueue.push(strategy_);
        emit StrategyAdded(strategy_, debtRatio_, externalDepositFee_);

        // Recalculate pool level externalDepositFee. This should be called at the end of function
        _recalculatePoolExternalDepositFee();
    }

    /**
     * @notice Remove strategy and recalculate pool level external deposit fee.
     * @dev Revoke and remove strategy from array. Update withdraw queue.
     * Withdraw queue order should not change after remove.
     * Strategy can be removed only after it has paid all debt.
     * Use migrate strategy if debt is not paid and want to upgrade strategy.
     */
    function removeStrategy(uint256 index_) external onlyGovernor {
        address _strategy = strategies[index_];
        require(strategy[_strategy].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        require(strategy[_strategy].totalDebt == 0, Errors.TOTAL_DEBT_IS_NOT_ZERO);
        // Adjust totalDebtRatio
        totalDebtRatio -= strategy[_strategy].debtRatio;
        // Remove strategy
        delete strategy[_strategy];
        strategies[index_] = strategies[strategies.length - 1];
        strategies.pop();
        address[] memory _withdrawQueue = new address[](strategies.length);
        uint256 j;
        // After above update, withdrawQueue.length > strategies.length
        for (uint256 i; i < withdrawQueue.length; i++) {
            if (withdrawQueue[i] != _strategy) {
                _withdrawQueue[j] = withdrawQueue[i];
                j++;
            }
        }
        withdrawQueue = _withdrawQueue;
        emit StrategyRemoved(_strategy);

        // Recalculate pool level externalDepositFee.
        _recalculatePoolExternalDepositFee();
    }

    /**
     * @notice Update external deposit fee of strategy and recalculate pool level external deposit fee.
     * @param strategy_ Strategy address for which external deposit fee is being updated
     * @param externalDepositFee_ New external deposit fee
     */
    function updateExternalDepositFee(address strategy_, uint256 externalDepositFee_) external onlyGovernor {
        require(strategy[strategy_].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        require(externalDepositFee_ <= MAX_BPS, Errors.FEE_LIMIT_REACHED);
        uint256 _oldExternalDepositFee = strategy[strategy_].externalDepositFee;
        // Write to storage
        strategy[strategy_].externalDepositFee = externalDepositFee_;
        emit UpdatedExternalDepositFee(strategy_, _oldExternalDepositFee, externalDepositFee_);

        // Recalculate pool level externalDepositFee.
        _recalculatePoolExternalDepositFee();
    }

    ///////////////////////////// Only Keeper /////////////////////////////

    /**
     * @notice Recalculate pool external deposit fee. It is calculated using debtRatio and external deposit fee of each strategy.
     * @dev Whenever debtRatio changes recalculation is required. DebtRatio changes if strategy reports loss and in that case an
     * off chain application can watch for it and take action accordingly.
     * @dev This function is gas heavy hence we do not want to call during reportLoss.
     */
    function recalculatePoolExternalDepositFee() external onlyKeeper {
        _recalculatePoolExternalDepositFee();
    }

    /**
     * @dev Transfer given ERC20 token to pool
     * @param fromToken_ Token address to sweep
     */
    function sweep(address fromToken_) external virtual onlyKeeper {
        IERC20(fromToken_).safeTransfer(pool, IERC20(fromToken_).balanceOf(address(this)));
    }

    ///////////////////////////// Only Maintainer /////////////////////////////
    /**
     * @notice Update debt ratio.
     * @dev A strategy is retired when debtRatio is 0
     * @dev As debtRatio impacts pool level external deposit fee hence recalculate it after updating debtRatio.
     * @param strategy_ Strategy address for which debt ratio is being updated
     * @param debtRatio_ New debt ratio
     */
    function updateDebtRatio(address strategy_, uint256 debtRatio_) external onlyMaintainer {
        require(strategy[strategy_].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        // Update totalDebtRatio
        totalDebtRatio = (totalDebtRatio - strategy[strategy_].debtRatio) + debtRatio_;
        require(totalDebtRatio <= MAX_BPS, Errors.DEBT_RATIO_LIMIT_REACHED);
        emit UpdatedStrategyDebtRatio(strategy_, strategy[strategy_].debtRatio, debtRatio_);
        // Write to storage
        strategy[strategy_].debtRatio = debtRatio_;
        // Recalculate pool level externalDepositFee.
        _recalculatePoolExternalDepositFee();
    }

    /**
     * @notice Update withdraw queue. Withdraw queue is list of strategy in the order in which
     * funds should be withdrawn.
     * @dev Pool always keep some buffer amount to satisfy withdrawal request, any withdrawal
     * request higher than buffer will withdraw from withdraw queue. So withdrawQueue[0] will
     * be the first strategy where withdrawal request will be send.
     * @param withdrawQueue_ Ordered list of strategy.
     */
    function updateWithdrawQueue(address[] memory withdrawQueue_) external onlyMaintainer {
        uint256 _length = withdrawQueue_.length;
        require(_length == withdrawQueue.length && _length == strategies.length, Errors.INPUT_LENGTH_MISMATCH);
        for (uint256 i; i < _length; i++) {
            require(strategy[withdrawQueue_[i]].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        }
        withdrawQueue = withdrawQueue_;
    }

    //////////////////////////////// Only Pool ////////////////////////////////

    /**
     * @notice Decrease debt of strategy, also decrease totalDebt
     * @dev In case of withdraw from strategy, pool will decrease debt by amount withdrawn
     * @param strategy_ Strategy Address
     * @param decreaseBy_ Amount by which strategy debt will be decreased
     */
    function decreaseDebt(address strategy_, uint256 decreaseBy_) external onlyPool {
        // A strategy may send more than its debt. This should never fail
        decreaseBy_ = _min(strategy[strategy_].totalDebt, decreaseBy_);
        strategy[strategy_].totalDebt -= decreaseBy_;
        totalDebt -= decreaseBy_;
    }

    /**
     * @notice Migrate existing strategy to new strategy.
     * @dev Migrating strategy aka old and new strategy should be of same type.
     * @dev New strategy will replace old strategy in strategy mapping,
     * strategies array, withdraw queue.
     * @param old_ Address of strategy being migrated
     * @param new_ Address of new strategy
     */
    function migrateStrategy(address old_, address new_) external onlyPool {
        require(strategy[old_].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        require(!strategy[new_].active, Errors.STRATEGY_IS_ACTIVE);
        StrategyConfig memory _newStrategy = StrategyConfig({
            active: true,
            interestFee: 0, // Obsolete
            debtRate: 0, // Obsolete
            lastRebalance: strategy[old_].lastRebalance,
            totalDebt: strategy[old_].totalDebt,
            totalLoss: 0,
            totalProfit: 0,
            debtRatio: strategy[old_].debtRatio,
            externalDepositFee: strategy[old_].externalDepositFee
        });
        delete strategy[old_];
        strategy[new_] = _newStrategy;

        // Strategies and withdrawQueue has same length but we still want
        // to iterate over them in different loop.
        for (uint256 i; i < strategies.length; i++) {
            if (strategies[i] == old_) {
                strategies[i] = new_;
                break;
            }
        }
        for (uint256 i; i < withdrawQueue.length; i++) {
            if (withdrawQueue[i] == old_) {
                withdrawQueue[i] = new_;
                break;
            }
        }
        emit StrategyMigrated(old_, new_);
    }

    /**
     * @dev Strategy call this in regular interval.
     * @param profit_ yield generated by strategy. Strategy get performance fee on this amount
     * @param loss_  Reduce debt ,also reduce debtRatio, increase loss in record.
     * @param payback_ strategy willing to payback outstanding above debtLimit. no performance fee on this amount.
     *  when governance has reduced debtRatio of strategy, strategy will report profit and payback amount separately.
     */
    function reportEarning(
        address strategy_,
        uint256 profit_,
        uint256 loss_,
        uint256 payback_
    ) external onlyPool returns (uint256 _actualPayback, uint256 _creditLine) {
        require(strategy[strategy_].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        require(IVesperPool(pool).token().balanceOf(strategy_) >= (profit_ + payback_), Errors.INSUFFICIENT_BALANCE);
        if (loss_ > 0) {
            _reportLoss(strategy_, loss_);
        }

        uint256 _overLimitDebt = _excessDebt(strategy_);
        _actualPayback = _min(_overLimitDebt, payback_);
        if (_actualPayback > 0) {
            strategy[strategy_].totalDebt -= _actualPayback;
            totalDebt -= _actualPayback;
        }
        _creditLine = _availableCreditLimit(strategy_);
        if (_creditLine > 0) {
            strategy[strategy_].totalDebt += _creditLine;
            totalDebt += _creditLine;
        }
        if (profit_ > 0) {
            strategy[strategy_].totalProfit += profit_;
        }
        strategy[strategy_].lastRebalance = block.timestamp;
        emit EarningReported(
            strategy_,
            profit_,
            loss_,
            _actualPayback,
            strategy[strategy_].totalDebt,
            totalDebt,
            _creditLine
        );
        return (_actualPayback, _creditLine);
    }

    /**
     * @notice Update strategy loss.
     * @param strategy_ Strategy which incur loss
     * @param loss_ Loss of strategy
     */
    function reportLoss(address strategy_, uint256 loss_) external onlyPool {
        require(strategy[strategy_].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        _reportLoss(strategy_, loss_);
        emit LossReported(strategy_, loss_);
    }

    ///////////////////////////////////////////////////////////////////////////
}