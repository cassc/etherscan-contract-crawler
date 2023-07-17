// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/math/Math.sol";
import "vesper-pools/contracts/interfaces/vesper/IPoolRewards.sol";
import "../Strategy.sol";
import "../../interfaces/frax-lend/IFraxLend.sol";

// solhint-disable var-name-mixedcase

/// @title This strategy will deposit collateral token in FraxLend and based on position it will
/// borrow Frax and supplied borrowed tokens to Vesper pool.
contract FraxLendVesperXy is Strategy {
    using SafeERC20 for IERC20;
    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.1.0";

    uint256 internal constant MAX_BPS = 10_000; //100%
    uint256 public minBorrowLimit = 7_000; // 70% of actual collateral factor of protocol
    uint256 public maxBorrowLimit = 8_500; // 85% of actual collateral factor of protocol

    IFraxLend internal immutable fraxLend;
    address public immutable borrowToken;

    // Destination Grow Pool for borrowed Token
    IVesperPool public immutable vPool;
    // VSP token address
    address public immutable vsp;

    // FraxLend constants
    uint256 internal immutable MAX_LTV;
    uint256 internal immutable LTV_PRECISION;
    uint256 internal immutable EXCHANGE_PRECISION;

    event UpdatedBorrowLimit(
        uint256 previousMinBorrowLimit,
        uint256 newMinBorrowLimit,
        uint256 previousMaxBorrowLimit,
        uint256 newMaxBorrowLimit
    );

    constructor(
        address pool_,
        address swapper_,
        address fraxLend_,
        address frax_,
        address vPool_,
        address vsp_,
        string memory name_
    ) Strategy(pool_, swapper_, fraxLend_) {
        require(fraxLend_ != address(0), "frax-lend-address-is-null");
        require(frax_ != address(0), "frax-address-is-null");
        require(vsp_ != address(0), "vsp-address-is-null");
        require(address(IVesperPool(vPool_).token()) == frax_, "invalid-grow-pool");
        require(IFraxLend(fraxLend_).collateralContract() == address(collateralToken), "collateral-mismatch");
        fraxLend = IFraxLend(fraxLend_);
        borrowToken = frax_;
        vPool = IVesperPool(vPool_);
        vsp = vsp_;
        NAME = name_;

        (uint256 _LTV_PRECISION, , , , uint256 _EXCHANGE_PRECISION, , , ) = fraxLend.getConstants();
        LTV_PRECISION = _LTV_PRECISION;
        EXCHANGE_PRECISION = _EXCHANGE_PRECISION;
        MAX_LTV = fraxLend.maxLTV();
    }

    /// @notice Gets amount of borrowed token in strategy + borrowed tokens deposited in vPool
    function borrowBalance() external view returns (uint256) {
        return IERC20(borrowToken).balanceOf(address(this)) + _getYTokensInProtocol();
    }

    function isReservedToken(address token_) public view virtual override returns (bool) {
        return
            token_ == address(fraxLend) ||
            token_ == address(collateralToken) ||
            token_ == borrowToken ||
            token_ == address(vPool);
    }

    /// @notice Returns total collateral locked in the strategy
    function tvl() external view override returns (uint256) {
        return fraxLend.userCollateralBalance(address(this)) + collateralToken.balanceOf(address(this));
    }

    /// @dev Approve all required tokens
    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        address _swapper = address(swapper);
        collateralToken.safeApprove(address(fraxLend), amount_);
        collateralToken.safeApprove(_swapper, amount_);
        IERC20(borrowToken).safeApprove(_swapper, amount_);
        IERC20(borrowToken).safeApprove(address(fraxLend), amount_);
        IERC20(borrowToken).safeApprove(address(vPool), amount_);
        IERC20(vsp).safeApprove(_swapper, amount_);
    }

    /**
     * @dev Repay borrow and withdraw collateral
     * @param newStrategy_ Address of new strategy.
     */
    function _beforeMigration(address newStrategy_) internal override {
        require(IStrategy(newStrategy_).token() == address(fraxLend), "wrong-receipt-token");
        // Accrue and update interest
        fraxLend.addInterest();
        _repay(_borrowedFromFraxLend());

        fraxLend.removeCollateral(fraxLend.userCollateralBalance(address(this)), address(this));
    }

    function _borrowedFromFraxLend() internal view returns (uint256) {
        return fraxLend.toBorrowAmount(fraxLend.userBorrowShares(address(this)), true);
    }

    /**
     * @dev Calculate borrow and repay amount based on current collateral and new deposit/withdraw amount.
     * @param depositAmount_ deposit amount
     * @param withdrawAmount_ withdraw amount
     * @return _borrowAmount borrow more amount
     * @return _repayAmount repay amount to keep ltv within limits
     */
    function _calculateBorrowPosition(
        uint256 depositAmount_,
        uint256 withdrawAmount_
    ) internal view returns (uint256 _borrowAmount, uint256 _repayAmount) {
        require(depositAmount_ == 0 || withdrawAmount_ == 0, "all-input-gt-zero");
        uint256 _borrowed = _borrowedFromFraxLend();
        // If maximum borrow limit set to 0 then repay borrow
        if (maxBorrowLimit == 0) {
            return (0, _borrowed);
        }

        uint256 _collateralSupplied = fraxLend.userCollateralBalance(address(this));

        // In case of withdraw, withdrawAmount_ may be greater than _collateralSupplied
        uint256 _hypotheticalCollateral;
        if (depositAmount_ > 0) {
            _hypotheticalCollateral = _collateralSupplied + depositAmount_;
        } else if (_collateralSupplied > withdrawAmount_) {
            _hypotheticalCollateral = _collateralSupplied - withdrawAmount_;
        }
        // It is collateral:asset ratio. i.e. how much collateral to buy 1e18 asset
        uint224 _exchangeRate = fraxLend.exchangeRateInfo().exchangeRate;

        // Max borrow limit in borrow token i.e. FRAX.
        uint256 _maxBorrowPossible = (_hypotheticalCollateral * MAX_LTV * EXCHANGE_PRECISION) /
            (LTV_PRECISION * _exchangeRate);

        // If maxBorrow is zero, we should repay total amount of borrow
        if (_maxBorrowPossible == 0) {
            return (0, _borrowed);
        }

        // Safe buffer to avoid liquidation due to price variations.
        uint256 _borrowUpperBound = (_maxBorrowPossible * maxBorrowLimit) / MAX_BPS;

        // Borrow up to _borrowLowerBound and keep buffer of _borrowUpperBound - _borrowLowerBound for price variation
        uint256 _borrowLowerBound = (_maxBorrowPossible * minBorrowLimit) / MAX_BPS;

        // If current borrow is greater than max borrow, then repay to achieve safe position else borrow more.
        if (_borrowed > _borrowUpperBound) {
            // If borrow > upperBound then it is greater than lowerBound too.
            _repayAmount = _borrowed - _borrowLowerBound;
        } else if (_borrowed < _borrowLowerBound) {
            _borrowAmount = _borrowLowerBound - _borrowed;
            uint256 _availableLiquidity = _getAvailableLiquidity();
            if (_borrowAmount > _availableLiquidity) {
                _borrowAmount = _availableLiquidity;
            }
        }
    }

    /// @dev Claim VSP rewards
    function _claimRewards() internal override returns (address, uint256) {
        address _poolRewards = vPool.poolRewards();
        if (_poolRewards != address(0)) {
            IPoolRewards(_poolRewards).claimReward(address(this));
        }
        return (vsp, IERC20(vsp).balanceOf(address(this)));
    }

    /// @dev Deposit collateral in protocol and adjust borrow position
    function _deposit() internal {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        (uint256 _borrowAmount, uint256 _repayAmount) = _calculateBorrowPosition(_collateralBalance, 0);
        if (_repayAmount > 0) {
            // Repay to maintain safe position
            _repay(_repayAmount);
            // Read collateral balance again as repay() may change balance
            _collateralBalance = collateralToken.balanceOf(address(this));
            if (_collateralBalance > 0) {
                fraxLend.addCollateral(_collateralBalance, address(this));
            }
        } else if (_borrowAmount > 0) {
            // Happy path, mint more borrow more
            // borrowAsset will deposit collateral and then borrow FRAX
            fraxLend.borrowAsset(_borrowAmount, _collateralBalance, address(this));
            // Deposit all borrow token, FRAX, we have.
            vPool.deposit(IERC20(borrowToken).balanceOf(address(this)));
        }
    }

    function _getAvailableLiquidity() internal view virtual returns (uint256) {
        uint256 _totalAsset = fraxLend.totalAsset().amount;
        uint256 _totalBorrow = fraxLend.totalBorrow().amount;
        return _totalAsset > _totalBorrow ? _totalAsset - _totalBorrow : 0;
    }

    function _getYTokensInProtocol() internal view returns (uint256) {
        return (vPool.pricePerShare() * vPool.balanceOf(address(this))) / 1e18;
    }

    /// @dev Deposit collateral aka X in FraxLend.
    function _mintX(uint256 _amount) internal virtual {
        if (_amount > 0) {
            fraxLend.addCollateral(_amount, address(this));
        }
    }

    function _rebalance() internal override returns (uint256 _profit, uint256 _loss, uint256 _payback) {
        // Accrue and update interest
        fraxLend.addInterest();
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        uint256 _yTokensBorrowed = _borrowedFromFraxLend();
        uint256 _yTokensHere = IERC20(borrowToken).balanceOf(address(this));
        uint256 _yTokensInProtocol = _getYTokensInProtocol();
        uint256 _totalYTokens = _yTokensHere + _yTokensInProtocol;

        // _borrow increases every block. Convert collateral to borrowToken.
        if (_yTokensBorrowed > _totalYTokens) {
            _swapToBorrowToken(_yTokensBorrowed - _totalYTokens);
        } else {
            // When _yTokensInProtocol exceeds _yTokensBorrowed from protocol
            // then we have profit from investing borrow tokens. _yTokensHere is profit.
            if (_yTokensInProtocol > _yTokensBorrowed) {
                _withdrawY(_yTokensInProtocol - _yTokensBorrowed);
                _yTokensHere = IERC20(borrowToken).balanceOf(address(this));
            }
            if (_yTokensHere > 0) {
                _safeSwapExactInput(borrowToken, address(collateralToken), _yTokensHere);
            }
        }

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _collateralInFraxLend = fraxLend.userCollateralBalance(address(this));
        uint256 _totalCollateral = _collateralInFraxLend + _collateralHere;

        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
        } else {
            _loss = _totalDebt - _totalCollateral;
        }
        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_collateralHere < _profitAndExcessDebt) {
            _withdrawHere(_profitAndExcessDebt - _collateralHere);
            _collateralHere = collateralToken.balanceOf(address(this));
        }

        // Set actual payback first and then profit. Make sure _collateralHere >= _payback + profit.
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;

        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _deposit();
    }

    /**
     * @dev Repay borrow amount
     * @param _repayAmount BorrowToken amount that we should repay to maintain safe position.
     */
    function _repay(uint256 _repayAmount) internal {
        if (_repayAmount > 0) {
            uint256 _totalYTokens = IERC20(borrowToken).balanceOf(address(this)) + _getYTokensInProtocol();
            // Liability is more than what we have.
            // To repay loan - convert all rewards to collateral, if asked, and redeem collateral(if needed).
            // This scenario is rare and if system works okay it will/might happen during final repay only.
            if (_repayAmount > _totalYTokens) {
                uint256 _yTokensBorrowed = _borrowedFromFraxLend();
                // For example this is final repay and 100 blocks has passed since last withdraw/rebalance,
                // _yTokensBorrowed is increasing due to interest. Now if _repayAmount > _borrowBalanceHere is true
                // _yTokensBorrowed > _borrowBalanceHere is also true.
                // To maintain safe position we always try to keep _yTokensBorrowed = _borrowBalanceHere

                // Swap collateral to borrowToken to repay borrow and also maintain safe position
                // Here borrowToken amount needed is (_yTokensBorrowed - _borrowBalanceHere)
                _swapToBorrowToken(_yTokensBorrowed - _totalYTokens);
            }
            _repayY(_repayAmount);
        }
    }

    /// @dev Repay Y to FraxLend. Withdraw Y from end protocol if applicable.
    function _repayY(uint256 amount_) internal virtual {
        _withdrawY(amount_);
        uint256 _fraxShare = fraxLend.toBorrowShares(amount_, false);
        fraxLend.repayAsset(_fraxShare, address(this));
    }

    /**
     * @dev Swap given token to borrowToken
     * @param shortOnBorrow_ Expected output of this swap
     */
    function _swapToBorrowToken(uint256 shortOnBorrow_) internal {
        // Looking for _amountIn using fixed output amount
        uint256 _amountIn = swapper.getAmountIn(address(collateralToken), borrowToken, shortOnBorrow_);
        if (_amountIn > 0) {
            uint256 _collateralHere = collateralToken.balanceOf(address(this));
            // If we do not have enough _from token to get expected output, either get
            // some _from token or adjust expected output.
            if (_amountIn > _collateralHere) {
                // Redeem some collateral, so that we have enough collateral to get expected output
                fraxLend.removeCollateral(_amountIn - _collateralHere, address(this));
            }
            swapper.swapExactOutput(address(collateralToken), borrowToken, shortOnBorrow_, _amountIn, address(this));
        }
    }

    function _withdrawHere(uint256 amount_) internal override {
        // Accrue and update interest
        fraxLend.addInterest();
        (, uint256 _repayAmount) = _calculateBorrowPosition(0, amount_);
        _repay(_repayAmount);

        // Get minimum of amount_ and collateral supplied and _available collateral in FraxLend
        uint256 _withdrawAmount = Math.min(
            amount_,
            Math.min(fraxLend.userCollateralBalance(address(this)), fraxLend.totalCollateral())
        );
        fraxLend.removeCollateral(_withdrawAmount, address(this));
    }

    function _withdrawY(uint256 amount_) internal virtual {
        uint256 _pricePerShare = vPool.pricePerShare();
        uint256 _shares = (amount_ * 1e18) / _pricePerShare;
        _shares = amount_ > ((_shares * _pricePerShare) / 1e18) ? _shares + 1 : _shares;
        uint256 _maxShares = vPool.balanceOf(address(this));
        _shares = _shares > _maxShares ? _maxShares : _shares;
        if (_shares > 0) {
            vPool.withdraw(_shares);
        }
    }

    /************************************************************************************************
     *                          Governor/admin/keeper function                                      *
     ***********************************************************************************************/
    /**
     * @notice Recover extra borrow tokens from strategy
     * @dev If we get liquidation in protocol, we will have borrowToken sitting in strategy.
     * This function allows to recover idle borrow token amount.
     * @param _amountToRecover Amount of borrow token we want to recover in 1 call.
     *      Set it 0 to recover all available borrow tokens
     */
    function recoverBorrowToken(uint256 _amountToRecover) external onlyKeeper {
        uint256 _borrowBalanceHere = IERC20(borrowToken).balanceOf(address(this));
        uint256 _borrow = _borrowedFromFraxLend();

        if (_borrowBalanceHere > _borrow) {
            uint256 _extraBorrowBalance = _borrowBalanceHere - _borrow;
            uint256 _recoveryAmount = (_amountToRecover > 0 && _extraBorrowBalance > _amountToRecover)
                ? _amountToRecover
                : _extraBorrowBalance;
            // Do swap and transfer
            uint256 _collateralBefore = collateralToken.balanceOf(address(this));
            _safeSwapExactInput(borrowToken, address(collateralToken), _recoveryAmount);
            collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)) - _collateralBefore);
        }
    }

    /**
     * @notice Repay all borrow amount and set min borrow limit to 0.
     * @dev This action usually done when loss is detected in strategy.
     * @dev 0 borrow limit make sure that any future rebalance do not borrow again.
     */
    function repayAll() external onlyKeeper {
        // Accrue and update interest
        fraxLend.addInterest();
        _repay(_borrowedFromFraxLend());
        minBorrowLimit = 0;
        maxBorrowLimit = 0;
    }

    /**
     * @notice Update upper and lower borrow limit. Usually maxBorrowLimit < 100% of actual collateral factor of protocol.
     * @dev It is possible to set 0 as _minBorrowLimit to not borrow anything
     * @param _minBorrowLimit It is % of actual collateral factor of protocol
     * @param _maxBorrowLimit It is % of actual collateral factor of protocol
     */
    function updateBorrowLimit(uint256 _minBorrowLimit, uint256 _maxBorrowLimit) external onlyGovernor {
        require(_maxBorrowLimit < MAX_BPS, "invalid-max-borrow-limit");
        // set _maxBorrowLimit and _minBorrowLimit to zero to disable borrow;
        require(
            (_maxBorrowLimit == 0 && _minBorrowLimit == 0) || _maxBorrowLimit > _minBorrowLimit,
            "max-should-be-higher-than-min"
        );
        emit UpdatedBorrowLimit(minBorrowLimit, _minBorrowLimit, maxBorrowLimit, _maxBorrowLimit);
        // To avoid liquidation due to price variations maxBorrowLimit is a collateral factor that is less than actual collateral factor of protocol
        minBorrowLimit = _minBorrowLimit;
        maxBorrowLimit = _maxBorrowLimit;
    }
}