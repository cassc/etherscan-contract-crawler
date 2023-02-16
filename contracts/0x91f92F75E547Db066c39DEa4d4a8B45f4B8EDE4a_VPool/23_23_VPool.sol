// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../dependencies/openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PoolERC20Permit.sol";
import "./PoolStorage.sol";
import "../Errors.sol";
import "../Governable.sol";
import "../Pausable.sol";
import "../interfaces/vesper/IPoolAccountant.sol";
import "../interfaces/vesper/IPoolRewards.sol";
import "vesper-commons/contracts/interfaces/vesper/IStrategy.sol";

/// @title Holding pool share token
// solhint-disable no-empty-blocks
contract VPool is Initializable, PoolERC20Permit, Governable, Pausable, ReentrancyGuard, PoolStorageV3 {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    string public constant VERSION = "5.1.0";

    uint256 public constant MAX_BPS = 10_000;
    // For simplicity we are assuming 365 days as 1 year
    uint256 public constant ONE_YEAR = 365 days;

    event UpdatedMaximumProfitAsFee(uint256 oldMaxProfitAsFee, uint256 newMaxProfitAsFee);
    event UpdatedMinimumDepositLimit(uint256 oldDepositLimit, uint256 newDepositLimit);
    event Deposit(address indexed owner, uint256 shares, uint256 amount);
    event Withdraw(address indexed owner, uint256 shares, uint256 amount);
    event UpdatedUniversalFee(uint256 oldUniversalFee, uint256 newUniversalFee);
    event UpdatedPoolRewards(address indexed previousPoolRewards, address indexed newPoolRewards);
    event UpdatedWithdrawFee(uint256 previousWithdrawFee, uint256 newWithdrawFee);
    event UniversalFeePaid(uint256 strategyDebt, uint256 profit, uint256 fee);

    // We are using constructor to initialize implementation with basic details
    constructor(string memory name_, string memory symbol_, address token_) PoolERC20(name_, symbol_) {
        // 0x0 is acceptable as has no effect on functionality
        token = IERC20(token_);
    }

    /// @dev Equivalent to constructor for proxy. It can be called only once per proxy.
    function initialize(
        string memory name_,
        string memory symbol_,
        address token_,
        address poolAccountant_
    ) public initializer {
        require(token_ != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        require(poolAccountant_ != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        __ERC20_init(name_, symbol_);
        __ERC20Permit_init(name_);
        __Governable_init();
        token = IERC20(token_);

        require(_keepers.add(_msgSender()), Errors.ADD_IN_LIST_FAILED);
        require(_maintainers.add(_msgSender()), Errors.ADD_IN_LIST_FAILED);
        poolAccountant = poolAccountant_;
        universalFee = 200; // 2%
        maxProfitAsFee = 5_000; // 50%
        minDepositLimit = 1;
    }

    modifier onlyKeeper() {
        require(governor == _msgSender() || _keepers.contains(_msgSender()), "not-a-keeper");
        _;
    }

    modifier onlyMaintainer() {
        require(governor == _msgSender() || _maintainers.contains(_msgSender()), "not-a-maintainer");
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
        return IPoolAccountant(poolAccountant).availableCreditLimit(strategy_);
    }

    /**
     * @notice Calculate how much shares user will get for given amount. Also return externalDepositFee if any.
     * @param amount_ Collateral amount
     * @return _shares Amount of share that user will get
     * @dev Amount should be >= minimum deposit limit which default to 1
     */
    function calculateMintage(uint256 amount_) public view returns (uint256 _shares) {
        require(amount_ >= minDepositLimit, Errors.INVALID_COLLATERAL_AMOUNT);
        uint256 _externalDepositFee = (amount_ * IPoolAccountant(poolAccountant).externalDepositFee()) / MAX_BPS;
        _shares = _calculateShares(amount_ - _externalDepositFee);
    }

    /**
     * @notice Calculate universal fee for calling strategy. This is only strategy function.
     * @dev Earn strategies will call this during rebalance.
     */
    function calculateUniversalFee(uint256 profit_) external view returns (uint256 _fee) {
        return _calculateUniversalFee(_msgSender(), profit_);
    }

    /**
     * @notice Deposit ERC20 tokens and receive pool shares depending on the current share price.
     * @param amount_ ERC20 token amount.
     */
    function deposit(uint256 amount_) external nonReentrant whenNotPaused {
        _updateRewards(_msgSender());
        _deposit(amount_);
    }

    /**
     * @notice Deposit ERC20 tokens and claim rewards if any
     * @param amount_ ERC20 token amount.
     */
    function depositAndClaim(uint256 amount_) external nonReentrant whenNotPaused {
        _claimRewards(_msgSender());
        _deposit(amount_);
    }

    /**
     * @notice Deposit ERC20 tokens with permit aka gasless approval.
     * @param amount_ ERC20 token amount.
     * @param deadline_ The time at which signature will expire
     * @param v_ The recovery byte of the signature
     * @param r_ Half of the ECDSA signature pair
     * @param s_ Half of the ECDSA signature pair
     */
    function depositWithPermit(
        uint256 amount_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external nonReentrant whenNotPaused {
        IERC20Permit(address(token)).permit(_msgSender(), address(this), amount_, deadline_, v_, r_, s_);
        _updateRewards(_msgSender());
        _deposit(amount_);
    }

    /**
     * @notice Debt above current debt limit
     * @param strategy_ Address of strategy
     */
    function excessDebt(address strategy_) external view returns (uint256) {
        return IPoolAccountant(poolAccountant).excessDebt(strategy_);
    }

    function getStrategies() external view returns (address[] memory) {
        return IPoolAccountant(poolAccountant).getStrategies();
    }

    function getWithdrawQueue() public view returns (address[] memory) {
        return IPoolAccountant(poolAccountant).getWithdrawQueue();
    }

    /**
     * @notice Get price per share
     * @dev Return value will be in token defined decimals.
     */
    function pricePerShare() public view returns (uint256) {
        if (totalSupply() == 0 || totalValue() == 0) {
            return 10 ** IERC20Metadata(address(token)).decimals();
        }
        return (totalValue() * 1e18) / totalSupply();
    }

    /**
     * @notice Strategy call this in regular interval. Only strategy function.
     * @param profit_ yield generated by strategy. Strategy get performance fee on this amount
     * @param loss_  Reduce debt ,also reduce debtRatio, increase loss in record.
     * @param payback_ strategy willing to payback outstanding above debtLimit. no performance fee on this amount.
     *  when governance has reduced debtRatio of strategy, strategy will report profit and payback amount separately.
     */
    function reportEarning(uint256 profit_, uint256 loss_, uint256 payback_) external {
        address _strategy = _msgSender();
        // Calculate universal fee
        if (profit_ > 0) {
            (, , , uint256 _lastRebalanceAt, uint256 _totalDebt, , , , ) = IPoolAccountant(poolAccountant).strategy(
                _strategy
            );
            uint256 _fee = _calculateUniversalFee(_lastRebalanceAt, _totalDebt, profit_);
            // Mint shares equal to universal fee
            if (_fee > 0) {
                _mint(IStrategy(_strategy).feeCollector(), _calculateShares(_fee));
                emit UniversalFeePaid(_totalDebt, profit_, _fee);
            }
        }

        // Report earning in pool accountant
        (uint256 _actualPayback, uint256 _creditLine) = IPoolAccountant(poolAccountant).reportEarning(
            _strategy,
            profit_,
            loss_,
            payback_
        );
        uint256 _totalPayback = profit_ + _actualPayback;
        // After payback, if strategy has credit line available then send more fund to strategy
        // If payback is more than available credit line then get fund from strategy
        if (_totalPayback < _creditLine) {
            token.safeTransfer(_strategy, _creditLine - _totalPayback);
        } else if (_totalPayback > _creditLine) {
            token.safeTransferFrom(_strategy, address(this), _totalPayback - _creditLine);
        }
    }

    /**
     * @notice Report loss outside of rebalance activity.
     * @dev Some strategies pay deposit fee thus realizing loss at deposit.
     * For example: Curve's 3pool has some slippage due to deposit of one asset in 3pool.
     * Strategy may want report this loss instead of waiting for next rebalance.
     * @param loss_ Loss that strategy want to report
     */
    function reportLoss(uint256 loss_) external {
        if (loss_ > 0) {
            IPoolAccountant(poolAccountant).reportLoss(_msgSender(), loss_);
        }
    }

    function strategy(
        address strategy_
    )
        public
        view
        returns (
            bool _active,
            uint256 _interestFee, // Obsolete
            uint256 _debtRate, // Obsolete
            uint256 _lastRebalance,
            uint256 _totalDebt,
            uint256 _totalLoss,
            uint256 _totalProfit,
            uint256 _debtRatio,
            uint256 _externalDepositFee
        )
    {
        return IPoolAccountant(poolAccountant).strategy(strategy_);
    }

    /// @dev Returns the token stored in the pool. It will be in token defined decimals.
    function tokensHere() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /// @notice Get total debt of pool
    function totalDebt() external view returns (uint256) {
        return IPoolAccountant(poolAccountant).totalDebt();
    }

    /**
     * @notice Get total debt of given strategy
     * @param strategy_ Strategy address
     */
    function totalDebtOf(address strategy_) external view returns (uint256) {
        return IPoolAccountant(poolAccountant).totalDebtOf(strategy_);
    }

    /// @notice Get total debt ratio. Total debt ratio helps us keep buffer in pool
    function totalDebtRatio() external view returns (uint256) {
        return IPoolAccountant(poolAccountant).totalDebtRatio();
    }

    /**
     * @notice Returns sum of token locked in other contracts and token stored in the pool.
     * It will be in token defined decimals.
     */
    function totalValue() public view returns (uint256) {
        return IPoolAccountant(poolAccountant).totalDebt() + tokensHere();
    }

    /**
     * @notice Withdraw collateral based on given shares and the current share price.
     * Burn remaining shares and return collateral.
     * @param shares_ Pool shares. It will be in 18 decimals.
     */
    function withdraw(uint256 shares_) external nonReentrant whenNotShutdown {
        _updateRewards(_msgSender());
        _withdraw(shares_);
    }

    /**
     * @notice Withdraw collateral and claim rewards if any
     * @param shares_ Pool shares. It will be in 18 decimals.
     */
    function withdrawAndClaim(uint256 shares_) external nonReentrant whenNotShutdown {
        _claimRewards(_msgSender());
        _withdraw(shares_);
    }

    /**
     * @dev Hook that is called just after burning tokens.
     * @param amount_ Collateral amount in collateral token defined decimals.
     */
    function _afterBurning(uint256 amount_) internal virtual returns (uint256) {
        token.safeTransfer(_msgSender(), amount_);
        return amount_;
    }

    /**
     * @dev Before burning hook.
     * withdraw amount from strategies
     */
    function _beforeBurning(uint256 share_) private returns (uint256 _amount, bool _isPartial) {
        _amount = (share_ * pricePerShare()) / 1e18;
        uint256 _tokensHere = tokensHere();
        // Check for partial withdraw scenario
        // If we do not have enough tokens then withdraw whats needed from strategy
        if (_amount > _tokensHere) {
            // Strategy may withdraw partial
            _withdrawCollateral(_amount - _tokensHere);
            _tokensHere = tokensHere();
            if (_amount > _tokensHere) {
                _amount = _tokensHere;
                _isPartial = true;
            }
        }
        require(_amount > 0, Errors.INVALID_COLLATERAL_AMOUNT);
    }

    /**
     * @dev Calculate shares to mint/burn based on the current share price and given amount.
     * @param amount_ Collateral amount in collateral token defined decimals.
     * @return share amount in 18 decimal
     */
    function _calculateShares(uint256 amount_) private view returns (uint256) {
        uint256 _share = ((amount_ * 1e18) / pricePerShare());
        return amount_ > ((_share * pricePerShare()) / 1e18) ? _share + 1 : _share;
    }

    /**
     * @dev Calculate universal fee based on strategy's TVL, profit earned and duration between rebalance and now.
     */
    function _calculateUniversalFee(address strategy_, uint256 profit_) private view returns (uint256 _fee) {
        // Calculate universal fee
        (, , , uint256 _lastRebalance, uint256 _totalDebt, , , , ) = IPoolAccountant(poolAccountant).strategy(
            strategy_
        );
        return _calculateUniversalFee(_lastRebalance, _totalDebt, profit_);
    }

    function _calculateUniversalFee(
        uint256 lastRebalance_,
        uint256 totalDebt_,
        uint256 profit_
    ) private view returns (uint256 _fee) {
        _fee = (universalFee * (block.timestamp - lastRebalance_) * totalDebt_) / (MAX_BPS * ONE_YEAR);
        uint256 _maxFee = (profit_ * maxProfitAsFee) / MAX_BPS;
        if (_fee > _maxFee) {
            _fee = _maxFee;
        }
    }

    /// @notice claim rewards of account
    function _claimRewards(address account_) internal {
        if (poolRewards != address(0)) {
            IPoolRewards(poolRewards).claimReward(account_);
        }
    }

    /// @dev Deposit incoming token and mint pool token i.e. shares.
    function _deposit(uint256 amount_) internal {
        uint256 _shares = calculateMintage(amount_);
        token.safeTransferFrom(_msgSender(), address(this), amount_);
        _mint(_msgSender(), _shares);
        emit Deposit(_msgSender(), _shares, amount_);
    }

    /// @dev Update pool rewards of sender and receiver during transfer.
    /// @dev _beforeTokenTransfer can be used to replace _transfer and _updateRewards but that
    /// will increase gas cost of deposit, withdraw and transfer.
    function _transfer(address sender_, address recipient_, uint256 amount_) internal override {
        if (poolRewards != address(0)) {
            IPoolRewards(poolRewards).updateReward(sender_);
            IPoolRewards(poolRewards).updateReward(recipient_);
        }
        super._transfer(sender_, recipient_, amount_);
    }

    function _updateRewards(address account_) internal {
        if (poolRewards != address(0)) {
            IPoolRewards(poolRewards).updateReward(account_);
        }
    }

    /// @dev Burns shares and returns the collateral value, after fee, of those.
    function _withdraw(uint256 shares_) internal {
        require(shares_ > 0, Errors.INVALID_SHARE_AMOUNT);

        (uint256 _amountWithdrawn, bool _isPartial) = _beforeBurning(shares_);
        // There may be scenarios when pool is not able to withdraw all of requested amount
        if (_isPartial) {
            // Recalculate proportional share on actual amount withdrawn
            uint256 _proportionalShares = _calculateShares(_amountWithdrawn);
            if (_proportionalShares < shares_) {
                shares_ = _proportionalShares;
            }
        }
        _burn(_msgSender(), shares_);
        _afterBurning(_amountWithdrawn);
        emit Withdraw(_msgSender(), shares_, _amountWithdrawn);
    }

    function _withdrawCollateral(uint256 amount_) internal {
        // Withdraw amount from queue
        uint256 _debt;
        uint256 _balanceBefore;
        uint256 _amountWithdrawn;
        uint256 _totalAmountWithdrawn;
        address[] memory _withdrawQueue = getWithdrawQueue();
        uint256 _len = _withdrawQueue.length;
        for (uint256 i; i < _len; i++) {
            uint256 _amountNeeded = amount_ - _totalAmountWithdrawn;
            address _strategy = _withdrawQueue[i];
            _debt = IPoolAccountant(poolAccountant).totalDebtOf(_strategy);
            if (_debt == 0) {
                continue;
            }
            if (_amountNeeded > _debt) {
                // Should not withdraw more than current debt of strategy.
                _amountNeeded = _debt;
            }
            _balanceBefore = tokensHere();
            //solhint-disable no-empty-blocks
            try IStrategy(_strategy).withdraw(_amountNeeded) {} catch {
                continue;
            }
            _amountWithdrawn = tokensHere() - _balanceBefore;
            // Adjusting totalDebt. Assuming that during next reportEarning(), strategy will report loss if amountWithdrawn < _amountNeeded
            IPoolAccountant(poolAccountant).decreaseDebt(_strategy, _amountWithdrawn);
            _totalAmountWithdrawn += _amountWithdrawn;
            if (_totalAmountWithdrawn >= amount_) {
                // withdraw done
                break;
            }
        }
    }

    /************************************************************************************************
     *                                     Authorized function                                      *
     ***********************************************************************************************/

    ////////////////////////////// Only Governor //////////////////////////////

    /**
     * @notice Migrate existing strategy to new strategy.
     * @dev Migrating strategy aka old and new strategy should be of same type.
     * @param old_ Address of strategy being migrated
     * @param new_ Address of new strategy
     */
    function migrateStrategy(address old_, address new_) external onlyGovernor {
        require(
            IStrategy(new_).pool() == address(this) && IStrategy(old_).pool() == address(this),
            Errors.INVALID_STRATEGY
        );
        IPoolAccountant(poolAccountant).migrateStrategy(old_, new_);
        IStrategy(old_).migrate(new_);
    }

    /**
     * Only Governor:: Update maximum profit that can be used as universal fee
     * @param newMaxProfitAsFee_ New max profit as fee
     */
    function updateMaximumProfitAsFee(uint256 newMaxProfitAsFee_) external onlyGovernor {
        require(newMaxProfitAsFee_ != maxProfitAsFee, Errors.SAME_AS_PREVIOUS);
        emit UpdatedMaximumProfitAsFee(maxProfitAsFee, newMaxProfitAsFee_);
        maxProfitAsFee = newMaxProfitAsFee_;
    }

    /**
     * Only Governor:: Update minimum deposit limit
     * @param newLimit_ New minimum deposit limit
     */
    function updateMinimumDepositLimit(uint256 newLimit_) external onlyGovernor {
        require(newLimit_ > 0, Errors.INVALID_INPUT);
        require(newLimit_ != minDepositLimit, Errors.SAME_AS_PREVIOUS);
        emit UpdatedMinimumDepositLimit(minDepositLimit, newLimit_);
        minDepositLimit = newLimit_;
    }

    /**
     * @notice Update pool rewards address for this pool
     * @param newPoolRewards_ new pool rewards address
     */
    function updatePoolRewards(address newPoolRewards_) external onlyGovernor {
        require(newPoolRewards_ != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        emit UpdatedPoolRewards(poolRewards, newPoolRewards_);
        poolRewards = newPoolRewards_;
    }

    /**
     * @notice Update universal fee for this pool
     * @dev Format: 1500 = 15% fee, 100 = 1%
     * @param newUniversalFee_ new universal fee
     */
    function updateUniversalFee(uint256 newUniversalFee_) external onlyGovernor {
        require(newUniversalFee_ <= MAX_BPS, Errors.FEE_LIMIT_REACHED);
        emit UpdatedUniversalFee(universalFee, newUniversalFee_);
        universalFee = newUniversalFee_;
    }

    ///////////////////////////// Only Keeper ///////////////////////////////
    /**
     * @dev Transfer given ERC20 token to governor
     * @param fromToken_ Token address to sweep
     */
    function sweepERC20(address fromToken_) external onlyKeeper {
        require(fromToken_ != address(token), Errors.NOT_ALLOWED_TO_SWEEP);
        IERC20(fromToken_).safeTransfer(governor, IERC20(fromToken_).balanceOf(address(this)));
    }

    function pause() external onlyKeeper {
        _pause();
    }

    function unpause() external onlyKeeper {
        _unpause();
    }

    function shutdown() external onlyKeeper {
        _shutdown();
    }

    function open() external onlyKeeper {
        _open();
    }

    /// @notice Return list of keepers
    function keepers() external view returns (address[] memory) {
        return _keepers.values();
    }

    function isKeeper(address address_) external view returns (bool) {
        return _keepers.contains(address_);
    }

    /**
     * @notice Add given address in keepers list.
     * @param keeperAddress_ keeper address to add.
     */
    function addKeeper(address keeperAddress_) external onlyKeeper {
        require(_keepers.add(keeperAddress_), Errors.ADD_IN_LIST_FAILED);
    }

    /**
     * @notice Remove given address from keepers list.
     * @param keeperAddress_ keeper address to remove.
     */
    function removeKeeper(address keeperAddress_) external onlyKeeper {
        require(_keepers.remove(keeperAddress_), Errors.REMOVE_FROM_LIST_FAILED);
    }

    /// @notice Return list of maintainers
    function maintainers() external view returns (address[] memory) {
        return _maintainers.values();
    }

    function isMaintainer(address address_) external view returns (bool) {
        return _maintainers.contains(address_);
    }

    /**
     * @notice Add given address in maintainers list.
     * @param maintainerAddress_ maintainer address to add.
     */
    function addMaintainer(address maintainerAddress_) external onlyKeeper {
        require(_maintainers.add(maintainerAddress_), Errors.ADD_IN_LIST_FAILED);
    }

    /**
     * @notice Remove given address from maintainers list.
     * @param maintainerAddress_ maintainer address to remove.
     */
    function removeMaintainer(address maintainerAddress_) external onlyKeeper {
        require(_maintainers.remove(maintainerAddress_), Errors.REMOVE_FROM_LIST_FAILED);
    }

    ///////////////////////////////////////////////////////////////////////////
}