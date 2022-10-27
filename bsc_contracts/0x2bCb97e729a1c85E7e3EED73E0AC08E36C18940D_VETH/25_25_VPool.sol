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

    string public constant VERSION = "5.0.2";

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
    constructor(
        string memory _name,
        string memory _symbol,
        address _token
    ) PoolERC20(_name, _symbol) {
        // 0x0 is acceptable as has no effect on functionality
        token = IERC20(_token);
    }

    /// @dev Equivalent to constructor for proxy. It can be called only once per proxy.
    function initialize(
        string memory _name,
        string memory _symbol,
        address _token,
        address _poolAccountant
    ) public initializer {
        require(_token != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        require(_poolAccountant != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        __ERC20_init(_name, _symbol);
        __ERC20Permit_init(_name);
        __Governable_init();
        token = IERC20(_token);

        require(_keepers.add(_msgSender()), Errors.ADD_IN_LIST_FAILED);
        require(_maintainers.add(_msgSender()), Errors.ADD_IN_LIST_FAILED);
        poolAccountant = _poolAccountant;
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
     * @notice Deposit ERC20 tokens and receive pool shares depending on the current share price.
     * @param _amount ERC20 token amount.
     */
    function deposit(uint256 _amount) external nonReentrant whenNotPaused {
        _updateRewards(_msgSender());
        _deposit(_amount);
    }

    /**
     * @notice Deposit ERC20 tokens and claim rewards if any
     * @param _amount ERC20 token amount.
     */
    function depositAndClaim(uint256 _amount) external nonReentrant whenNotPaused {
        _depositAndClaim(_amount);
    }

    /**
     * @notice Deposit ERC20 tokens with permit aka gasless approval.
     * @param _amount ERC20 token amount.
     * @param _deadline The time at which signature will expire
     * @param _v The recovery byte of the signature
     * @param _r Half of the ECDSA signature pair
     * @param _s Half of the ECDSA signature pair
     */
    function depositWithPermit(
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external nonReentrant whenNotPaused {
        IERC20Permit(address(token)).permit(_msgSender(), address(this), _amount, _deadline, _v, _r, _s);
        _updateRewards(_msgSender());
        _deposit(_amount);
    }

    /**
     * @notice Withdraw collateral based on given shares and the current share price.
     * Burn remaining shares and return collateral. Claim rewards if there is any
     * @dev Deprecated method. Keeping this method here for backward compatibility.
     * @param _shares Pool shares. It will be in 18 decimals.
     */
    function whitelistedWithdraw(uint256 _shares) external nonReentrant whenNotShutdown {
        _claimRewards(_msgSender());
        _withdraw(_shares);
    }

    /**
     * @notice Withdraw collateral based on given shares and the current share price.
     * Burn remaining shares and return collateral.
     * @param _shares Pool shares. It will be in 18 decimals.
     */
    function withdraw(uint256 _shares) external nonReentrant whenNotShutdown {
        _updateRewards(_msgSender());
        _withdraw(_shares);
    }

    /**
     * @notice Withdraw collateral and claim rewards if any
     * @param _shares Pool shares. It will be in 18 decimals.
     */
    function withdrawAndClaim(uint256 _shares) external nonReentrant whenNotShutdown {
        _withdrawAndClaim(_shares);
    }

    /**
     * @notice Transfer tokens to multiple recipient
     * @dev Address array and amount array are 1:1 and are in order.
     * @param _recipients array of recipient addresses
     * @param _amounts array of token amounts
     * @return true/false
     */
    function multiTransfer(address[] calldata _recipients, uint256[] calldata _amounts) external returns (bool) {
        require(_recipients.length == _amounts.length, Errors.INPUT_LENGTH_MISMATCH);
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(transfer(_recipients[i], _amounts[i]), Errors.MULTI_TRANSFER_FAILED);
        }
        return true;
    }

    /**
     * @notice Strategy call this in regular interval. Only strategy function.
     * @param _profit yield generated by strategy. Strategy get performance fee on this amount
     * @param _loss  Reduce debt ,also reduce debtRatio, increase loss in record.
     * @param _payback strategy willing to payback outstanding above debtLimit. no performance fee on this amount.
     *  when governance has reduced debtRatio of strategy, strategy will report profit and payback amount separately.
     */
    function reportEarning(
        uint256 _profit,
        uint256 _loss,
        uint256 _payback
    ) external {
        address _strategy = _msgSender();
        // Calculate universal fee
        if (_profit > 0) {
            (, , , uint256 _lastRebalanceAt, uint256 _totalDebt, , , , ) =
                IPoolAccountant(poolAccountant).strategy(_strategy);
            uint256 _fee = _calculateUniversalFee(_lastRebalanceAt, _totalDebt, _profit);
            // Mint shares equal to universal fee
            if (_fee > 0) {
                _mint(IStrategy(_strategy).feeCollector(), _calculateShares(_fee));
                emit UniversalFeePaid(_totalDebt, _profit, _fee);
            }
        }

        // Report earning in pool accountant
        (uint256 _actualPayback, uint256 _creditLine) =
            IPoolAccountant(poolAccountant).reportEarning(_strategy, _profit, _loss, _payback);
        uint256 _totalPayback = _profit + _actualPayback;
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
     * @param _loss Loss that strategy want to report
     */
    function reportLoss(uint256 _loss) external {
        if (_loss > 0) {
            IPoolAccountant(poolAccountant).reportLoss(_msgSender(), _loss);
        }
    }

    /**
     * @dev Transfer given ERC20 token to governor
     * @param _fromToken Token address to sweep
     */
    function sweepERC20(address _fromToken) external onlyKeeper {
        require(_fromToken != address(token), Errors.NOT_ALLOWED_TO_SWEEP);
        IERC20(_fromToken).safeTransfer(governor, IERC20(_fromToken).balanceOf(address(this)));
    }

    /**
     * @notice Get available credit limit of strategy. This is the amount strategy can borrow from pool
     * @dev Available credit limit is calculated based on current debt of pool and strategy, current debt limit of pool and strategy.
     * credit available = min(pool's debt limit, strategy's debt limit, max debt per rebalance)
     * when some strategy do not pay back outstanding debt, this impact credit line of other strategy if totalDebt of pool >= debtLimit of pool
     * @param _strategy Strategy address
     */
    function availableCreditLimit(address _strategy) external view returns (uint256) {
        return IPoolAccountant(poolAccountant).availableCreditLimit(_strategy);
    }

    /**
     * @notice Calculate universal fee for calling strategy. This is only strategy function.
     * @dev Earn strategies will call this during rebalance.
     */
    function calculateUniversalFee(uint256 _profit) external view returns (uint256 _fee) {
        return _calculateUniversalFee(_msgSender(), _profit);
    }

    /**
     * @notice Debt above current debt limit
     * @param _strategy Address of strategy
     */
    function excessDebt(address _strategy) external view returns (uint256) {
        return IPoolAccountant(poolAccountant).excessDebt(_strategy);
    }

    function getStrategies() external view returns (address[] memory) {
        return IPoolAccountant(poolAccountant).getStrategies();
    }

    /// @notice Get total debt of pool
    function totalDebt() external view returns (uint256) {
        return IPoolAccountant(poolAccountant).totalDebt();
    }

    /**
     * @notice Get total debt of given strategy
     * @param _strategy Strategy address
     */
    function totalDebtOf(address _strategy) external view returns (uint256) {
        return IPoolAccountant(poolAccountant).totalDebtOf(_strategy);
    }

    /// @notice Get total debt ratio. Total debt ratio helps us keep buffer in pool
    function totalDebtRatio() external view returns (uint256) {
        return IPoolAccountant(poolAccountant).totalDebtRatio();
    }

    /**
     * @notice Calculate how much shares user will get for given amount. Also return externalDepositFee if any.
     * @param _amount Collateral amount
     * @return _shares Amount of share that user will get
     * @dev Amount should be >= minimum deposit limit which default to 1
     */
    function calculateMintage(uint256 _amount) public view returns (uint256 _shares) {
        require(_amount >= minDepositLimit, Errors.INVALID_COLLATERAL_AMOUNT);
        uint256 _externalDepositFee = (_amount * IPoolAccountant(poolAccountant).externalDepositFee()) / MAX_BPS;
        _shares = _calculateShares(_amount - _externalDepositFee);
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
            return 10**IERC20Metadata(address(token)).decimals();
        }
        return (totalValue() * 1e18) / totalSupply();
    }

    function strategy(address _strategy)
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
        return IPoolAccountant(poolAccountant).strategy(_strategy);
    }

    /// @dev Returns the token stored in the pool. It will be in token defined decimals.
    function tokensHere() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice Returns sum of token locked in other contracts and token stored in the pool.
     * It will be in token defined decimals.
     */
    function totalValue() public view returns (uint256) {
        return IPoolAccountant(poolAccountant).totalDebt() + tokensHere();
    }

    /**
     * @dev Hook that is called just after burning tokens.
     * @param _amount Collateral amount in collateral token defined decimals.
     */
    function _afterBurning(uint256 _amount) internal virtual returns (uint256) {
        token.safeTransfer(_msgSender(), _amount);
        return _amount;
    }

    /// @notice claim rewards of account
    function _claimRewards(address _account) internal {
        if (poolRewards != address(0)) {
            IPoolRewards(poolRewards).claimReward(_account);
        }
    }

    /// @dev Deposit incoming token and mint pool token i.e. shares.
    function _deposit(uint256 _amount) internal {
        uint256 _shares = calculateMintage(_amount);
        token.safeTransferFrom(_msgSender(), address(this), _amount);
        _mint(_msgSender(), _shares);
        emit Deposit(_msgSender(), _shares, _amount);
    }

    /// @dev Deposit token and claim rewards if any
    function _depositAndClaim(uint256 _amount) internal {
        _claimRewards(_msgSender());
        _deposit(_amount);
    }

    /// @dev Update pool rewards of sender and receiver during transfer.
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (poolRewards != address(0)) {
            IPoolRewards(poolRewards).updateReward(sender);
            IPoolRewards(poolRewards).updateReward(recipient);
        }
        super._transfer(sender, recipient, amount);
    }

    function _updateRewards(address _account) internal {
        if (poolRewards != address(0)) {
            IPoolRewards(poolRewards).updateReward(_account);
        }
    }

    /// @dev Burns shares and returns the collateral value, after fee, of those.
    function _withdraw(uint256 _shares) internal {
        require(_shares > 0, Errors.INVALID_SHARE_AMOUNT);

        (uint256 _amountWithdrawn, bool _isPartial) = _beforeBurning(_shares);
        // There may be scenarios when pool is not able to withdraw all of requested amount
        if (_isPartial) {
            // Recalculate proportional share on actual amount withdrawn
            uint256 _proportionalShares = _calculateShares(_amountWithdrawn);
            if (_proportionalShares < _shares) {
                _shares = _proportionalShares;
            }
        }
        _burn(_msgSender(), _shares);
        _afterBurning(_amountWithdrawn);
        emit Withdraw(_msgSender(), _shares, _amountWithdrawn);
    }

    /// @dev Withdraw collateral and claim rewards if any
    function _withdrawAndClaim(uint256 _shares) internal {
        _claimRewards(_msgSender());
        _withdraw(_shares);
    }

    function _withdrawCollateral(uint256 _amount) internal {
        // Withdraw amount from queue
        uint256 _debt;
        uint256 _balanceAfter;
        uint256 _balanceBefore;
        uint256 _amountWithdrawn;
        uint256 _totalAmountWithdrawn;
        address[] memory _withdrawQueue = getWithdrawQueue();
        uint256 _len = _withdrawQueue.length;
        for (uint256 i; i < _len; i++) {
            uint256 _amountNeeded = _amount - _totalAmountWithdrawn;
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
            _balanceAfter = tokensHere();
            _amountWithdrawn = _balanceAfter - _balanceBefore;
            // Adjusting totalDebt. Assuming that during next reportEarning(), strategy will report loss if amountWithdrawn < _amountNeeded
            IPoolAccountant(poolAccountant).decreaseDebt(_strategy, _amountWithdrawn);
            _totalAmountWithdrawn += _amountWithdrawn;
            if (_totalAmountWithdrawn >= _amount) {
                // withdraw done
                break;
            }
        }
    }

    /**
     * @dev Before burning hook.
     * withdraw amount from strategies
     */
    function _beforeBurning(uint256 _share) private returns (uint256 _actualWithdrawn, bool _isPartial) {
        uint256 _amount = (_share * pricePerShare()) / 1e18;
        uint256 _tokensHere = tokensHere();
        _actualWithdrawn = _amount;
        // Check for partial withdraw scenario
        // If we do not have enough tokens then withdraw whats needed from strategy
        if (_amount > _tokensHere) {
            // Strategy may withdraw partial
            _withdrawCollateral(_amount - _tokensHere);
            _tokensHere = tokensHere();
            if (_amount > _tokensHere) {
                _actualWithdrawn = _tokensHere;
                _isPartial = true;
            }
        }
        require(_actualWithdrawn > 0, Errors.INVALID_COLLATERAL_AMOUNT);
    }

    /**
     * @dev Calculate shares to mint/burn based on the current share price and given amount.
     * @param _amount Collateral amount in collateral token defined decimals.
     * @return share amount in 18 decimal
     */
    function _calculateShares(uint256 _amount) private view returns (uint256) {
        uint256 _share = ((_amount * 1e18) / pricePerShare());
        return _amount > ((_share * pricePerShare()) / 1e18) ? _share + 1 : _share;
    }

    /**
     * @dev Calculate universal fee based on strategy's TVL, profit earned and duration between rebalance and now.
     */
    function _calculateUniversalFee(address _strategy, uint256 _profit) private view returns (uint256 _fee) {
        // Calculate universal fee
        (, , , uint256 _lastRebalance, uint256 _totalDebt, , , , ) =
            IPoolAccountant(poolAccountant).strategy(_strategy);
        return _calculateUniversalFee(_lastRebalance, _totalDebt, _profit);
    }

    function _calculateUniversalFee(
        uint256 _lastRebalance,
        uint256 _totalDebt,
        uint256 _profit
    ) private view returns (uint256 _fee) {
        _fee = (universalFee * (block.timestamp - _lastRebalance) * _totalDebt) / (MAX_BPS * ONE_YEAR);
        uint256 _maxFee = (_profit * maxProfitAsFee) / MAX_BPS;
        if (_fee > _maxFee) {
            _fee = _maxFee;
        }
    }

    ////////////////////////////// Only Governor //////////////////////////////

    /**
     * @notice Migrate existing strategy to new strategy.
     * @dev Migrating strategy aka old and new strategy should be of same type.
     * @param _old Address of strategy being migrated
     * @param _new Address of new strategy
     */
    function migrateStrategy(address _old, address _new) external onlyGovernor {
        require(
            IStrategy(_new).pool() == address(this) && IStrategy(_old).pool() == address(this),
            Errors.INVALID_STRATEGY
        );
        IPoolAccountant(poolAccountant).migrateStrategy(_old, _new);
        IStrategy(_old).migrate(_new);
    }

    /**
     * Only Governor:: Update maximum profit that can be used as universal fee
     * @param _newMaxProfitAsFee New max profit as fee
     */
    function updateMaximumProfitAsFee(uint256 _newMaxProfitAsFee) external onlyGovernor {
        require(_newMaxProfitAsFee != maxProfitAsFee, Errors.SAME_AS_PREVIOUS);
        emit UpdatedMaximumProfitAsFee(maxProfitAsFee, _newMaxProfitAsFee);
        maxProfitAsFee = _newMaxProfitAsFee;
    }

    /**
     * Only Governor:: Update minimum deposit limit
     * @param _newLimit New minimum deposit limit
     */
    function updateMinimumDepositLimit(uint256 _newLimit) external onlyGovernor {
        require(_newLimit > 0, Errors.INVALID_INPUT);
        require(_newLimit != minDepositLimit, Errors.SAME_AS_PREVIOUS);
        emit UpdatedMinimumDepositLimit(minDepositLimit, _newLimit);
        minDepositLimit = _newLimit;
    }

    /**
     * @notice Update universal fee for this pool
     * @dev Format: 1500 = 15% fee, 100 = 1%
     * @param _newUniversalFee new universal fee
     */
    function updateUniversalFee(uint256 _newUniversalFee) external onlyGovernor {
        require(_newUniversalFee <= MAX_BPS, Errors.FEE_LIMIT_REACHED);
        emit UpdatedUniversalFee(universalFee, _newUniversalFee);
        universalFee = _newUniversalFee;
    }

    /**
     * @notice Update pool rewards address for this pool
     * @param _newPoolRewards new pool rewards address
     */
    function updatePoolRewards(address _newPoolRewards) external onlyGovernor {
        require(_newPoolRewards != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        emit UpdatedPoolRewards(poolRewards, _newPoolRewards);
        poolRewards = _newPoolRewards;
    }

    ///////////////////////////// Only Keeper ///////////////////////////////
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

    function isKeeper(address _address) external view returns (bool) {
        return _keepers.contains(_address);
    }

    /**
     * @notice Add given address in keepers list.
     * @param _keeperAddress keeper address to add.
     */
    function addKeeper(address _keeperAddress) external onlyKeeper {
        require(_keepers.add(_keeperAddress), Errors.ADD_IN_LIST_FAILED);
    }

    /**
     * @notice Remove given address from keepers list.
     * @param _keeperAddress keeper address to remove.
     */
    function removeKeeper(address _keeperAddress) external onlyKeeper {
        require(_keepers.remove(_keeperAddress), Errors.REMOVE_FROM_LIST_FAILED);
    }

    /// @notice Return list of maintainers
    function maintainers() external view returns (address[] memory) {
        return _maintainers.values();
    }

    function isMaintainer(address _address) external view returns (bool) {
        return _maintainers.contains(_address);
    }

    /**
     * @notice Add given address in maintainers list.
     * @param _maintainerAddress maintainer address to add.
     */
    function addMaintainer(address _maintainerAddress) external onlyKeeper {
        require(_maintainers.add(_maintainerAddress), Errors.ADD_IN_LIST_FAILED);
    }

    /**
     * @notice Remove given address from maintainers list.
     * @param _maintainerAddress maintainer address to remove.
     */
    function removeMaintainer(address _maintainerAddress) external onlyKeeper {
        require(_maintainers.remove(_maintainerAddress), Errors.REMOVE_FROM_LIST_FAILED);
    }

    ///////////////////////////////////////////////////////////////////////////
}