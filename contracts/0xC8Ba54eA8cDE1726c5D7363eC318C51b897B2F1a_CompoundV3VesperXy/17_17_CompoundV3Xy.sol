// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/dependencies/openzeppelin/contracts/utils/math/Math.sol";
import "../../Strategy.sol";
import "../../../interfaces/compound/ICompoundV3.sol";

// solhint-disable no-empty-blocks

/// @title This strategy will deposit collateral token in Compound V3 and based on position it will
/// borrow based token. Supply X borrow Y and keep borrowed amount here.
/// It does not handle ETH as collateral
contract CompoundV3Xy is Strategy {
    using SafeERC20 for IERC20;
    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.0.0";

    uint256 internal constant MAX_BPS = 10_000; //100%
    uint256 public minBorrowLimit = 7_000; // 70% of actual collateral factor of protocol
    uint256 public maxBorrowLimit = 8_500; // 85% of actual collateral factor of protocol

    IRewards public immutable compRewards;
    address public immutable rewardToken;
    IComet public immutable comet;
    address public immutable borrowToken;

    event UpdatedBorrowLimit(
        uint256 previousMinBorrowLimit,
        uint256 newMinBorrowLimit,
        uint256 previousMaxBorrowLimit,
        uint256 newMaxBorrowLimit
    );

    constructor(
        address pool_,
        address swapper_,
        address compRewards_,
        address rewardToken_,
        address comet_,
        address borrowToken_,
        string memory name_
    ) Strategy(pool_, swapper_, comet_) {
        require(compRewards_ != address(0), "rewards-address-is-zero");
        require(comet_ != address(0), "comet-address-is-zero");
        require(rewardToken_ != address(0), "reward-token-address-is-zero");

        compRewards = IRewards(compRewards_);
        rewardToken = rewardToken_;
        comet = IComet(comet_);
        borrowToken = borrowToken_;
        NAME = name_;
    }

    function isReservedToken(address token_) public view virtual override returns (bool) {
        return token_ == address(comet) || token_ == address(collateralToken) || token_ == borrowToken;
    }

    /// @notice Returns total collateral locked in the strategy
    function tvl() external view override returns (uint256) {
        return
            comet.collateralBalanceOf(address(this), address(collateralToken)) +
            collateralToken.balanceOf(address(this));
    }

    /// @dev Hook that executes after collateral borrow.
    function _afterBorrowY(uint256 amount_) internal virtual {}

    /// @notice Approve all required tokens
    function _approveToken(uint256 amount_) internal virtual override {
        super._approveToken(amount_);
        address _swapper = address(swapper);
        collateralToken.safeApprove(address(comet), amount_);
        collateralToken.safeApprove(_swapper, amount_);
        IERC20(borrowToken).safeApprove(address(comet), amount_);
        IERC20(borrowToken).safeApprove(_swapper, amount_);
        IERC20(rewardToken).safeApprove(_swapper, amount_);
    }

    /**
     * @notice Claim rewardToken and transfer to new strategy
     * @param newStrategy_ Address of new strategy.
     */
    function _beforeMigration(address newStrategy_) internal override {
        require(IStrategy(newStrategy_).token() == address(comet), "wrong-receipt-token");
        _repay(comet.borrowBalanceOf(address(this)), false);
        _withdrawHere(comet.collateralBalanceOf(address(this), address(collateralToken)));
    }

    /// @dev Borrow Y from Compound. _afterBorrowY hook can be used to do anything with borrowed amount.
    /// @dev Override to handle ETH
    function _borrowY(uint256 amount_) internal virtual {
        if (amount_ > 0) {
            comet.withdraw(borrowToken, amount_);
            _afterBorrowY(amount_);
        }
    }

    /**
     * @notice Calculate borrow and repay amount based on current collateral and new deposit/withdraw amount.
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
        uint256 _borrowed = comet.borrowBalanceOf(address(this));
        // If maximum borrow limit set to 0 then repay borrow
        if (maxBorrowLimit == 0) {
            return (0, _borrowed);
        }

        uint256 _collateralSupplied = comet.collateralBalanceOf(address(this), address(collateralToken));

        // In case of withdraw, withdrawAmount_ may be greater than _collateralSupplied
        uint256 _hypotheticalCollateral;
        if (depositAmount_ > 0) {
            _hypotheticalCollateral = _collateralSupplied + depositAmount_;
        } else if (_collateralSupplied > withdrawAmount_) {
            _hypotheticalCollateral = _collateralSupplied - withdrawAmount_;
        }

        IComet.AssetInfo memory _collateralInfo = comet.getAssetInfoByAddress(address(collateralToken));

        // Compound V3 is using chainlink for price feed. Feed has 8 decimals
        uint256 _collateralTokenPrice = comet.getPrice(_collateralInfo.priceFeed);
        uint256 _borrowTokenPrice = comet.getPrice(comet.baseTokenPriceFeed());

        // Calculate max borrow based on collateral factor. CF is 18 decimal based
        uint256 _collateralForBorrowInUSD = (_hypotheticalCollateral *
            _collateralTokenPrice *
            _collateralInfo.borrowCollateralFactor) /
            (1e18 * 10 ** IERC20Metadata(address(collateralToken)).decimals());

        // Max borrow limit in borrow token
        uint256 _maxBorrowPossible = (_collateralForBorrowInUSD * 10 ** IERC20Metadata(borrowToken).decimals()) /
            _borrowTokenPrice;
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
        } else if (_borrowLowerBound > _borrowed) {
            _borrowAmount = _borrowLowerBound - _borrowed;
            uint256 _availableLiquidity = _getAvailableLiquidity();
            if (_borrowAmount > _availableLiquidity) {
                _borrowAmount = _availableLiquidity;
            }
        }
    }

    /// @dev Claim COMP and convert COMP into given token.
    function _claimRewardsAndConvertTo(address toToken_) internal virtual {
        if (rewardToken != address(0)) {
            compRewards.claim(address(comet), address(this), true);
            uint256 _rewardAmount = IERC20(rewardToken).balanceOf(address(this));
            if (_rewardAmount > 0) {
                _safeSwapExactInput(rewardToken, toToken_, _rewardAmount);
            }
        }
    }

    /// @dev Deposit collateral in Compound V3 and adjust borrow position
    function _deposit() internal {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));
        (uint256 _borrowAmount, uint256 _repayAmount) = _calculateBorrowPosition(_collateralBalance, 0);
        if (_repayAmount > 0) {
            // Repay to maintain safe position
            _repay(_repayAmount, false);
            _mintX(collateralToken.balanceOf(address(this)));
        } else {
            // Happy path, mint more borrow more
            _mintX(_collateralBalance);
            _borrowY(_borrowAmount);
        }
    }

    function _getAvailableLiquidity() internal view virtual returns (uint256) {
        uint256 _totalSupply = comet.totalSupply();
        uint256 _totalBorrow = comet.totalBorrow();
        return _totalSupply > _totalBorrow ? _totalSupply - _totalBorrow : 0;
    }

    function _getYTokensInProtocol() internal view virtual returns (uint256) {}

    /// @dev Deposit collateral aka X in Compound. Override to handle ETH
    function _mintX(uint256 _amount) internal virtual {
        if (_amount > 0) {
            comet.supply(address(collateralToken), _amount);
        }
    }

    function _rebalance() internal override returns (uint256 _profit, uint256 _loss, uint256 _payback) {
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        // Claim any reward we have.
        _claimRewardsAndConvertTo(address(collateralToken));

        uint256 _yTokensBorrowed = comet.borrowBalanceOf(address(this));
        uint256 _yTokensHere = IERC20(borrowToken).balanceOf(address(this));
        uint256 _yTokensInProtocol = _getYTokensInProtocol();
        uint256 _totalYTokens = _yTokensHere + _yTokensInProtocol;

        // _borrow increases every block. Convert collateral to borrowToken.
        if (_yTokensBorrowed > _totalYTokens) {
            _swapToBorrowToken(_yTokensBorrowed - _totalYTokens);
        } else {
            // When _yTokensInProtocol exceeds _yTokensBorrowed from Compound
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
        uint256 _collateralInCompound = comet.collateralBalanceOf(address(this), address(collateralToken));
        uint256 _totalCollateral = _collateralInCompound + _collateralHere;

        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
        } else {
            _loss = _totalDebt - _totalCollateral;
        }
        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_collateralHere < _profitAndExcessDebt) {
            uint256 _totalAmountToWithdraw = _profitAndExcessDebt - _collateralHere;
            if (_totalAmountToWithdraw > 0) {
                _withdrawHere(_totalAmountToWithdraw);
                _collateralHere = collateralToken.balanceOf(address(this));
            }
        }

        // Set actual payback first and then profit. Make sure _collateralHere >= _payback + profit.
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;

        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _deposit();
    }

    /**
     * @dev Repay borrow amount
     * @dev Claim rewardToken and convert to collateral. Swap collateral to borrowToken as needed.
     * @param _repayAmount BorrowToken amount that we should repay to maintain safe position.
     * @param _shouldClaimComp Flag indicating should we claim rewardToken and convert to collateral or not.
     */
    function _repay(uint256 _repayAmount, bool _shouldClaimComp) internal {
        if (_repayAmount > 0) {
            uint256 _totalYTokens = IERC20(borrowToken).balanceOf(address(this)) + _getYTokensInProtocol();
            // Liability is more than what we have.
            // To repay loan - convert all rewards to collateral, if asked, and redeem collateral(if needed).
            // This scenario is rare and if system works okay it will/might happen during final repay only.
            if (_repayAmount > _totalYTokens) {
                if (_shouldClaimComp) {
                    // Claim rewardToken and convert those to collateral.
                    _claimRewardsAndConvertTo(address(collateralToken));
                }

                uint256 _yTokensBorrowed = comet.borrowBalanceOf(address(this));
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

    /// @dev Repay Y to Compound V3. Withdraw Y from end protocol if applicable.
    /// @dev Override this to handle ETH
    function _repayY(uint256 amount_) internal virtual {
        _withdrawY(amount_);
        comet.supply(borrowToken, amount_);
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
                comet.withdraw(address(collateralToken), _amountIn - _collateralHere);
            }
            swapper.swapExactOutput(address(collateralToken), borrowToken, shortOnBorrow_, _amountIn, address(this));
        }
    }

    /// @dev Withdraw collateral here. Do not transfer to pool
    function _withdrawHere(uint256 amount_) internal override {
        (, uint256 _repayAmount) = _calculateBorrowPosition(0, amount_);
        _repay(_repayAmount, true);

        // Get minimum of amount_ and collateral supplied and _availableLiquidity of collateral
        uint256 _withdrawAmount = Math.min(
            amount_,
            Math.min(
                comet.collateralBalanceOf(address(this), address(collateralToken)),
                comet.totalsCollateral(address(collateralToken)).totalSupplyAsset
            )
        );
        comet.withdraw(address(collateralToken), _withdrawAmount);
    }

    function _withdrawY(uint256 _amount) internal virtual {}

    /************************************************************************************************
     *                          Governor/admin/keeper function                                      *
     ***********************************************************************************************/
    /**
     * @notice Recover extra borrow tokens from strategy
     * @dev If we get liquidation in Compound, we will have borrowToken sitting in strategy.
     * This function allows to recover idle borrow token amount.
     * @param _amountToRecover Amount of borrow token we want to recover in 1 call.
     *      Set it 0 to recover all available borrow tokens
     */
    function recoverBorrowToken(uint256 _amountToRecover) external onlyKeeper {
        uint256 _borrowBalanceHere = IERC20(borrowToken).balanceOf(address(this));
        uint256 _borrowInCompound = comet.borrowBalanceOf(address(this));

        if (_borrowBalanceHere > _borrowInCompound) {
            uint256 _extraBorrowBalance = _borrowBalanceHere - _borrowInCompound;
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
        _repay(comet.borrowBalanceOf(address(this)), true);
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