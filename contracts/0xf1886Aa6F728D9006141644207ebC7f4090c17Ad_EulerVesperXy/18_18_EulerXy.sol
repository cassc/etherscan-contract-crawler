// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/interfaces/vesper/IPoolRewards.sol";
import "vesper-pools/contracts/Errors.sol";
import "../../interfaces/euler/IEuler.sol";
import "../Strategy.sol";

// solhint-disable no-empty-blocks

/// @title Deposit Collateral in Euler and earn interest by depositing borrowed token in a Vesper Pool.
contract EulerXy is Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.0.0";

    uint32 internal constant EULER_CONFIG_FACTOR_SCALE = 4_000_000_000;
    uint256 internal constant MAX_BPS = 10_000; //100%
    uint256 public minBorrowLimit = 7_000; // 70% of actual collateral factor of protocol
    uint256 public maxBorrowLimit = 8_500; // 85% of actual collateral factor of protocol

    address public immutable euler;
    IEulerMarkets public immutable eulerMarkets;
    IExec public immutable eulerExec;
    IEulDistributor public immutable rewardDistributor;
    address public immutable rewardToken;
    address public immutable borrowToken;

    IEToken private immutable collateralEToken;
    IDToken private immutable collateralDToken;
    IEToken private immutable borrowEToken;
    IDToken public immutable borrowDToken; // Debt Token

    uint256 internal constant SUB_ACCOUNT_ID = 0;

    event UpdatedBorrowLimit(
        uint256 previousMinBorrowLimit,
        uint256 newMinBorrowLimit,
        uint256 previousMaxBorrowLimit,
        uint256 newMaxBorrowLimit
    );

    constructor(
        address pool_,
        address swapper_,
        address euler_,
        IEulerMarkets eulerMarkets_,
        IExec eulerExec_,
        IEulDistributor rewardDistributor_,
        address rewardToken_,
        address borrowToken_,
        string memory name_
    ) Strategy(pool_, swapper_, address(0)) {
        require(euler_ != address(0), "euler-protocol-address-is-null");
        require(address(eulerMarkets_) != address(0), "market-address-is-null");
        require(address(eulerExec_) != address(0), "euler-exec-address-is-null");
        require(address(rewardDistributor_) != address(0), "distributor-address-is-null");
        require(rewardToken_ != address(0), "reward-address-is-null");
        require(borrowToken_ != address(0), "borrow-token-address-is-null");

        euler = euler_;
        eulerMarkets = eulerMarkets_;
        eulerExec = eulerExec_;
        rewardDistributor = rewardDistributor_;
        rewardToken = rewardToken_;
        borrowToken = borrowToken_;
        NAME = name_;

        receiptToken = eulerMarkets_.underlyingToEToken(address(collateralToken));
        collateralEToken = IEToken(receiptToken);
        collateralDToken = IDToken(eulerMarkets_.underlyingToDToken(address(collateralToken)));

        borrowEToken = IEToken(eulerMarkets_.underlyingToEToken(borrowToken_));
        borrowDToken = IDToken(eulerMarkets_.underlyingToDToken(borrowToken_));

        eulerMarkets_.enterMarket(SUB_ACCOUNT_ID, address(collateralToken));
    }

    function isReservedToken(address token_) public view virtual override returns (bool) {
        return
            token_ == address(collateralToken) ||
            token_ == receiptToken ||
            token_ == borrowToken ||
            token_ == address(borrowDToken);
    }

    /// @notice Returns total collateral locked in the strategy
    function tvl() external view override returns (uint256) {
        return collateralEToken.balanceOfUnderlying(address(this)) + collateralToken.balanceOf(address(this));
    }

    /// @dev After borrowing Y Hook
    function _afterBorrowY(uint256 amount_) internal virtual {}

    /// @dev Approve all required tokens
    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        address _swapper = address(swapper);
        collateralToken.safeApprove(euler, amount_);
        collateralToken.safeApprove(_swapper, amount_);
        IERC20(borrowToken).safeApprove(euler, amount_);
        IERC20(borrowToken).safeApprove(_swapper, amount_);
        IERC20(rewardToken).safeApprove(_swapper, amount_);
    }

    /**
     * @dev Perform steps needed for migration
     * @param newStrategy_ Address of new strategy.
     */
    function _beforeMigration(address newStrategy_) internal virtual override {
        require(IStrategy(newStrategy_).token() == receiptToken, "wrong-receipt-token");
        _repayY(borrowDToken.balanceOf(address(this)));
    }

    /// @dev Before repaying Y Hook
    function _beforeRepayY(uint256 amount_) internal virtual {}

    /**
     * @dev Calculate borrow and repay amount based on current collateral and new deposit/withdraw amount.
     * @param depositAmount_ deposit amount
     * @param withdrawAmount_ withdraw amount
     * @param borrowed_ Borrow token borrowed
     * @param supplied_ Collateral supplied
     * @return _borrowAmount borrow more amount
     * @return _repayAmount repay amount to keep ltv within limit
     */
    function _calculateBorrowPosition(
        uint256 depositAmount_,
        uint256 withdrawAmount_,
        uint256 borrowed_,
        uint256 supplied_
    ) internal returns (uint256 _borrowAmount, uint256 _repayAmount) {
        require(depositAmount_ == 0 || withdrawAmount_ == 0, "all-input-gt-zero");
        // If maximum borrow limit set to 0 then repay borrow
        if (maxBorrowLimit == 0) {
            return (0, borrowed_);
        }
        // In case of withdraw, _amount can be greater than _supply
        uint256 _hypotheticalCollateral = depositAmount_ > 0 ? supplied_ + depositAmount_ : supplied_ > withdrawAmount_
            ? supplied_ - withdrawAmount_
            : 0;
        if (_hypotheticalCollateral == 0) {
            return (0, borrowed_);
        }
        // Price is denominated in ETH and has 18 decimals
        (uint256 _borrowTokenPrice, ) = eulerExec.getPrice(borrowToken);
        (uint256 _collateralTokenPrice, ) = eulerExec.getPrice(address(collateralToken));
        if (_borrowTokenPrice == 0 || _collateralTokenPrice == 0) {
            // Oracle problem. Lets payback all
            return (0, borrowed_);
        }

        // collateral and borrow factors are in 9 decimals.
        uint64 _cfOfCollateralToken = eulerMarkets.underlyingToAssetConfig(address(collateralToken)).collateralFactor;
        uint64 _bfOfBorrowToken = eulerMarkets.underlyingToAssetConfig(borrowToken).borrowFactor;
        uint64 _effectiveCF = (_cfOfCollateralToken * _bfOfBorrowToken) / EULER_CONFIG_FACTOR_SCALE;

        // Actual collateral based on price, collateral factor and borrow factor
        uint256 _actualCollateralForBorrow = (_hypotheticalCollateral * _effectiveCF * _collateralTokenPrice) /
            (EULER_CONFIG_FACTOR_SCALE * (10**IERC20Metadata(address(collateralToken)).decimals()));

        // Calculate max possible borrow amount
        uint256 _maxBorrowPossible = (_actualCollateralForBorrow * 10**IERC20Metadata(borrowToken).decimals()) /
            _borrowTokenPrice;

        if (_maxBorrowPossible == 0) {
            return (0, borrowed_);
        }
        // Safe buffer to avoid liquidation due to price variations.
        uint256 _borrowUpperBound = (_maxBorrowPossible * maxBorrowLimit) / MAX_BPS;

        // Borrow up to _borrowLowerBound and keep buffer of _borrowUpperBound - _borrowLowerBound for price variation
        uint256 _borrowLowerBound = (_maxBorrowPossible * minBorrowLimit) / MAX_BPS;

        // If current borrow is greater than max borrow, then repay to achieve safe position.
        if (borrowed_ > _borrowUpperBound) {
            // If borrow > upperBound then it is greater than lowerBound too.
            _repayAmount = borrowed_ - _borrowLowerBound;
        } else if (_borrowLowerBound > borrowed_) {
            _borrowAmount = _borrowLowerBound - borrowed_;
            uint256 _availableLiquidity = _getAvailableLiquidity(borrowEToken, borrowDToken);
            if (_borrowAmount > _availableLiquidity) {
                _borrowAmount = _availableLiquidity;
            }
        }
    }

    /**
     * @dev Swap collateral token to borrowToken to overcome borrowToken shortage.
     * @param shortOnBorrow_ Amount of borrow token
     */
    function _fixBorrowShortage(uint256 shortOnBorrow_) internal {
        // Looking for _amountIn using fixed output amount
        uint256 _amountIn = swapper.getAmountIn(address(collateralToken), borrowToken, shortOnBorrow_);
        if (_amountIn > 0) {
            uint256 _collateralHere = collateralToken.balanceOf(address(this));
            if (_amountIn > _collateralHere) {
                // Withdraw some collateral from Euler so that we have enough collateral to get expected output
                collateralEToken.withdraw(SUB_ACCOUNT_ID, _amountIn - _collateralHere);
            }
            swapper.swapExactOutput(address(collateralToken), borrowToken, shortOnBorrow_, _amountIn, address(this));
        }
    }

    function _getAvailableLiquidity(IEToken eToken_, IDToken dToken_)
        private
        view
        returns (uint256 _availableLiquidity)
    {
        // totalSupplyUnderlying on eToken = Total supply of underlying token
        // totalSupply on dToken = Total borrow issued.
        // Available liquidity of underlying token = (supply - borrow)
        uint256 _totalSupplyUnderlying = eToken_.totalSupplyUnderlying();
        uint256 _totalDebtUnderlying = dToken_.totalSupply();
        if (_totalSupplyUnderlying > _totalDebtUnderlying) {
            _availableLiquidity = _totalSupplyUnderlying - _totalDebtUnderlying;
        }
    }

    /// @dev Borrowed Y balance deposited here or elsewhere hook
    function _getInvestedBorrowBalance() internal view virtual returns (uint256) {
        return IERC20(borrowToken).balanceOf(address(this));
    }

    /**
     * @dev Generate report for pools accounting and also send profit and any payback to pool.
     */
    function _rebalance()
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _payback
        )
    {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _borrowed = borrowDToken.balanceOf(address(this));
        uint256 _investedBorrowBalance = _getInvestedBorrowBalance();

        // EUL rewards will be harvested by harvestEul function

        // if _borrow increases at higher rate than investedBorrow then strategy will be short on borrow token.
        if (_borrowed > _investedBorrowBalance) {
            _fixBorrowShortage(_borrowed - _investedBorrowBalance);
        } else {
            // When _investedBorrowBalance exceeds _borrow balance from Euler
            // Customize this hook to handle the excess borrowToken for profit
            _rebalanceBorrow(_investedBorrowBalance - _borrowed);
        }

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _supplied = collateralEToken.balanceOfUnderlying(address(this));
        uint256 _totalCollateral = _supplied + _collateralHere;
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
        } else {
            _loss = _totalDebt - _totalCollateral;
        }
        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        uint256 _totalAmountToWithdraw;
        if (_collateralHere < _profitAndExcessDebt) {
            _totalAmountToWithdraw = _profitAndExcessDebt - _collateralHere;
            _withdrawHere(_totalAmountToWithdraw, _borrowed, _supplied);
            _collateralHere = collateralToken.balanceOf(address(this));
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;

        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        uint256 _newSupply = collateralToken.balanceOf(address(this));
        if (_newSupply > 0) {
            collateralEToken.deposit(SUB_ACCOUNT_ID, _newSupply);
        }

        // There are scenarios when we want to call _calculateBorrowPosition and act on it.
        // 1. We have got some collateral from pool, this may lead to borrow more.
        // 2. Collateral and/or borrow token price is changed. Leads to reply or borrow.
        // 3. BorrowLimits are updated.
        // In some edge scenarios, below call is redundant but keeping it as is for simplicity.
        (uint256 _borrowAmount, uint256 _repayAmount) = _calculateBorrowPosition(
            0,
            0,
            borrowDToken.balanceOf(address(this)),
            collateralEToken.balanceOfUnderlying(address(this))
        );
        if (_repayAmount > 0) {
            // Repay _borrowAmount to maintain safe position
            _repayY(_repayAmount);
        } else if (_borrowAmount > 0) {
            borrowDToken.borrow(SUB_ACCOUNT_ID, _borrowAmount);
        }
        // If there is any borrowToken in contract, use those in _afterBorrowY hook
        uint256 _borrowTokenBalance = IERC20(borrowToken).balanceOf(address(this));
        if (_borrowTokenBalance > 0) {
            _afterBorrowY(_borrowTokenBalance);
        }
    }

    /// @notice Swap excess borrow for more collateral hook
    function _rebalanceBorrow(uint256 excessBorrow_) internal virtual {}

    function _repayY(uint256 amount_) internal virtual {
        _beforeRepayY(amount_);
        borrowDToken.repay(SUB_ACCOUNT_ID, amount_);
    }

    /// @dev Withdraw collateral here
    function _withdrawHere(uint256 withdrawAmount_) internal override {
        _withdrawHere(
            withdrawAmount_,
            borrowDToken.balanceOf(address(this)),
            collateralEToken.balanceOfUnderlying(address(this))
        );
    }

    function _withdrawHere(
        uint256 withdrawAmount_,
        uint256 borrowed_,
        uint256 supplied_
    ) internal {
        (, uint256 _repayAmount) = _calculateBorrowPosition(0, withdrawAmount_, borrowed_, supplied_);
        if (_repayAmount > 0) {
            _repayY(_repayAmount);
        }
        // To do safe withdraw, check withdrawAmount_ against collateral supplied
        // and available liquidity in Euler
        uint256 _possibleWithdraw = Math.min(
            withdrawAmount_,
            Math.min(supplied_, _getAvailableLiquidity(collateralEToken, collateralDToken))
        );
        if (_possibleWithdraw > 0) {
            collateralEToken.withdraw(SUB_ACCOUNT_ID, _possibleWithdraw);
        }
    }

    /************************************************************************************************
     *                          Governor/admin/keeper function                                      *
     ***********************************************************************************************/

    /**
     * @notice Claim EUL from Eul distributor and swap to collateral token.
     */
    function harvestEul(uint256 claimable_, bytes32[] calldata proof_) external onlyKeeper {
        rewardDistributor.claim(address(this), rewardToken, claimable_, proof_, address(0));
        uint256 _rewardAmount = IERC20(rewardToken).balanceOf(address(this));
        if (_rewardAmount > 0) {
            _safeSwapExactInput(rewardToken, address(collateralToken), _rewardAmount);
        }
    }

    /**
     * @notice Update upper and lower borrow limit. Usually maxBorrowLimit < 100% of actual collateral factor of protocol.
     * @dev It is possible to set maxBorrowLimit_ and minBorrowLimit_ as 0 to not borrow anything
     * @param minBorrowLimit_ It is % of actual collateral factor of protocol
     * @param maxBorrowLimit_ It is % of actual collateral factor of protocol
     */
    function updateBorrowLimit(uint256 minBorrowLimit_, uint256 maxBorrowLimit_) external onlyGovernor {
        require(maxBorrowLimit_ < MAX_BPS, "invalid-max-borrow-limit");
        // set maxBorrowLimit_ and minBorrowLimit_ to disable borrow;
        require(
            (maxBorrowLimit_ == 0 && minBorrowLimit_ == 0) || maxBorrowLimit_ > minBorrowLimit_,
            "max-should-be-higher-than-min"
        );
        emit UpdatedBorrowLimit(minBorrowLimit, minBorrowLimit_, maxBorrowLimit, maxBorrowLimit_);
        minBorrowLimit = minBorrowLimit_;
        maxBorrowLimit = maxBorrowLimit_;
    }
}