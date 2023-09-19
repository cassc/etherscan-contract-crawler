// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/interfaces/vesper/IPoolRewards.sol";
import "vesper-pools/contracts/Errors.sol";
import "../../../interfaces/aave/IAave.sol";
import "./AaveV3Incentive.sol";
import "../../Strategy.sol";

// solhint-disable no-empty-blocks

/// @title Deposit Collateral in Aave and earn interest by depositing borrowed token in a Vesper Pool.
contract AaveV3Xy is Strategy {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.1.0";

    uint256 internal constant MAX_BPS = 10_000; //100%
    uint256 public minBorrowLimit = 7_000; // 70% of actual collateral factor of protocol
    uint256 public maxBorrowLimit = 8_500; // 85% of actual collateral factor of protocol

    PoolAddressesProvider public immutable aaveAddressProvider;
    address public borrowToken;
    AToken public vdToken; // Variable Debt Token
    address internal aBorrowToken;

    IERC20 internal wrappedCollateral;

    event UpdatedBorrowLimit(
        uint256 previousMinBorrowLimit,
        uint256 newMinBorrowLimit,
        uint256 previousMaxBorrowLimit,
        uint256 newMaxBorrowLimit
    );

    constructor(
        address _pool,
        address _swapper,
        address _receiptToken,
        address _borrowToken,
        address _aaveAddressProvider,
        string memory _name
    ) Strategy(_pool, _swapper, _receiptToken) {
        NAME = _name;
        require(_aaveAddressProvider != address(0), "addressProvider-is-zero");
        wrappedCollateral = _getWrappedToken(collateralToken);
        require(
            AToken(_receiptToken).UNDERLYING_ASSET_ADDRESS() == address(wrappedCollateral),
            "invalid-receipt-token"
        );
        (address _aBorrowToken, , address _vdToken) = AaveProtocolDataProvider(
            PoolAddressesProvider(_aaveAddressProvider).getPoolDataProvider()
        ).getReserveTokensAddresses(_borrowToken);
        vdToken = AToken(_vdToken);
        borrowToken = _borrowToken;
        aBorrowToken = _aBorrowToken;
        aaveAddressProvider = PoolAddressesProvider(_aaveAddressProvider);
    }

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return
            _token == address(collateralToken) ||
            _token == receiptToken ||
            address(vdToken) == _token ||
            borrowToken == _token;
    }

    /// @notice Returns total collateral locked in the strategy
    function tvl() external view virtual override returns (uint256) {
        // receiptToken is aToken. aToken is 1:1 of collateral token
        return IERC20(receiptToken).balanceOf(address(this)) + collateralToken.balanceOf(address(this));
    }

    /// @notice After borrowing Y Hook
    function _afterBorrowY(uint256 _amount) internal virtual {}

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        address _swapper = address(swapper);
        wrappedCollateral.safeApprove(aaveAddressProvider.getPool(), _amount);
        wrappedCollateral.safeApprove(_swapper, _amount);
        IERC20(borrowToken).safeApprove(aaveAddressProvider.getPool(), _amount);
        IERC20(borrowToken).safeApprove(_swapper, _amount);
        try AToken(receiptToken).getIncentivesController() returns (address _aaveIncentivesController) {
            address[] memory _rewardTokens = AaveIncentivesController(_aaveIncentivesController).getRewardsList();
            for (uint256 i; i < _rewardTokens.length; ++i) {
                if (_rewardTokens[i] != address(collateralToken) && _rewardTokens[i] != borrowToken) {
                    IERC20(_rewardTokens[i]).safeApprove(_swapper, _amount);
                }
            }
            //solhint-disable no-empty-blocks
        } catch {}
    }

    /**
     * @notice Claim rewardToken and transfer to new strategy
     * @param _newStrategy Address of new strategy.
     */
    function _beforeMigration(address _newStrategy) internal virtual override {
        require(IStrategy(_newStrategy).token() == receiptToken, "wrong-receipt-token");
        _repayY(vdToken.balanceOf(address(this)), AaveLendingPool(aaveAddressProvider.getPool()));
    }

    /// @notice Before repaying Y Hook
    function _beforeRepayY(uint256 _amount) internal virtual {}

    /**
     * @notice Calculate borrow and repay amount based on current collateral and new deposit/withdraw amount.
     * @param _depositAmount deposit amount
     * @param _withdrawAmount withdraw amount
     * @return _borrowAmount borrow more amount
     * @return _repayAmount repay amount to keep ltv within limit
     */
    function _calculateBorrowPosition(
        uint256 _depositAmount,
        uint256 _withdrawAmount,
        uint256 _borrowed,
        uint256 _supplied
    ) internal view returns (uint256 _borrowAmount, uint256 _repayAmount) {
        require(_depositAmount == 0 || _withdrawAmount == 0, "all-input-gt-zero");
        // If maximum borrow limit set to 0 then repay borrow
        if (maxBorrowLimit == 0) {
            return (0, _borrowed);
        }
        // In case of withdraw, _amount can be greater than _supply
        uint256 _hypotheticalCollateral = _depositAmount > 0 ? _supplied + _depositAmount : _supplied > _withdrawAmount
            ? _supplied - _withdrawAmount
            : 0;
        if (_hypotheticalCollateral == 0) {
            return (0, _borrowed);
        }
        AaveOracle _aaveOracle = AaveOracle(aaveAddressProvider.getPriceOracle());

        uint256 _borrowTokenPrice = _aaveOracle.getAssetPrice(borrowToken);
        uint256 _collateralTokenPrice = _aaveOracle.getAssetPrice(address(wrappedCollateral));
        if (_borrowTokenPrice == 0 || _collateralTokenPrice == 0) {
            // Oracle problem. Lets payback all
            return (0, _borrowed);
        }
        // _collateralFactor in 4 decimal. 10_000 = 100%
        (, uint256 _collateralFactor, , , , , , , , ) = AaveProtocolDataProvider(
            aaveAddressProvider.getPoolDataProvider()
        ).getReserveConfigurationData(address(wrappedCollateral));

        // Collateral in base currency based on oracle price and cf;
        uint256 _actualCollateralForBorrow = (_hypotheticalCollateral * _collateralFactor * _collateralTokenPrice) /
            (MAX_BPS * (10 ** IERC20Metadata(address(wrappedCollateral)).decimals()));
        // Calculate max borrow possible in borrow token number
        uint256 _maxBorrowPossible = (_actualCollateralForBorrow *
            (10 ** IERC20Metadata(address(borrowToken)).decimals())) / _borrowTokenPrice;
        if (_maxBorrowPossible == 0) {
            return (0, _borrowed);
        }
        // Safe buffer to avoid liquidation due to price variations.
        uint256 _borrowUpperBound = (_maxBorrowPossible * maxBorrowLimit) / MAX_BPS;

        // Borrow up to _borrowLowerBound and keep buffer of _borrowUpperBound - _borrowLowerBound for price variation
        uint256 _borrowLowerBound = (_maxBorrowPossible * minBorrowLimit) / MAX_BPS;

        // If current borrow is greater than max borrow, then repay to achieve safe position.
        if (_borrowed > _borrowUpperBound) {
            // If borrow > upperBound then it is greater than lowerBound too.
            _repayAmount = _borrowed - _borrowLowerBound;
        } else if (_borrowLowerBound > _borrowed) {
            _borrowAmount = _borrowLowerBound - _borrowed;
            uint256 _availableLiquidity = IERC20(borrowToken).balanceOf(aBorrowToken);
            if (_borrowAmount > _availableLiquidity) {
                _borrowAmount = _availableLiquidity;
            }
        }
    }

    function _calculateUnwrapped(uint256 wrappedAmount_) internal view virtual returns (uint256) {
        return wrappedAmount_;
    }

    function _calculateWrapped(uint256 unwrappedAmount_) internal view virtual returns (uint256) {
        return unwrappedAmount_;
    }

    /// @dev Claim all rewards and convert to collateral.
    /// Overriding _claimAndSwapRewards will help child contract otherwise override _claimReward.
    function _claimAndSwapRewards() internal virtual override {
        (address[] memory _tokens, uint256[] memory _amounts) = AaveV3Incentive._claimRewards(receiptToken);
        uint256 _length = _tokens.length;
        for (uint256 i; i < _length; ++i) {
            if (_amounts[i] > 0 && _tokens[i] != address(wrappedCollateral)) {
                _safeSwapExactInput(_tokens[i], address(wrappedCollateral), _amounts[i]);
            }
        }
    }

    function _convertToWrapped(uint256 amount_) internal view virtual returns (uint256) {
        return amount_;
    }

    function _depositToAave(uint256 _amount, AaveLendingPool _aaveLendingPool) internal virtual {
        uint256 _wrappedAmount = _wrap(_amount);
        if (_wrappedAmount > 0) {
            try _aaveLendingPool.supply(address(wrappedCollateral), _wrappedAmount, address(this), 0) {} catch Error(
                string memory _reason
            ) {
                // Aave uses liquidityIndex and some other indexes as needed to normalize input.
                // If normalized input equals to 0 then error will be thrown with '56' error code.
                // CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
                // Hence discard error where error code is '56'
                require(bytes32(bytes(_reason)) == "56", "deposit failed");
            }
        }
    }

    function _getCollateralHere() internal virtual returns (uint256) {
        return collateralToken.balanceOf(address(this));
    }

    /// @notice Borrowed Y balance deposited here or elsewhere hook
    function _getInvestedBorrowBalance() internal view virtual returns (uint256) {
        return IERC20(borrowToken).balanceOf(address(this));
    }

    function _getWrappedToken(IERC20 unwrappedToken_) internal pure virtual returns (IERC20) {
        return unwrappedToken_;
    }

    /**
     * @dev Generate report for pools accounting and also send profit and any payback to pool.
     */
    function _rebalance() internal override returns (uint256 _profit, uint256 _loss, uint256 _payback) {
        // NOTE:: Pool has unwrapped as collateral and any state is also unwrapped amount
        uint256 _excessDebt = IVesperPool(pool).excessDebt(address(this));
        uint256 _borrowed = vdToken.balanceOf(address(this));
        uint256 _investedBorrowBalance = _getInvestedBorrowBalance();
        AaveLendingPool _aaveLendingPool = AaveLendingPool(aaveAddressProvider.getPool());

        // _borrow increases every block. Convert collateral to borrowToken.
        if (_borrowed > _investedBorrowBalance) {
            _swapToBorrowToken(_borrowed - _investedBorrowBalance, _aaveLendingPool);
        } else {
            // When _investedBorrowBalance exceeds _borrow balance from Aave
            // Customize this hook to handle the excess borrowToken for profit
            _rebalanceBorrow(_investedBorrowBalance - _borrowed);
        }
        uint256 _collateralHere = _getCollateralHere();
        uint256 _supplied = _calculateUnwrapped(IERC20(receiptToken).balanceOf(address(this)));
        uint256 _totalCollateral = _supplied + _collateralHere;
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
        } else {
            _loss = _totalDebt - _totalCollateral;
        }
        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_collateralHere < _profitAndExcessDebt) {
            uint256 _totalAmountToWithdraw = Math.min((_profitAndExcessDebt - _collateralHere), _supplied);
            if (_totalAmountToWithdraw > 0) {
                _withdrawHere(_totalAmountToWithdraw, _aaveLendingPool, _borrowed, _supplied);
                _collateralHere = collateralToken.balanceOf(address(this));
            }
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;

        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        // This is unwrapped balance if pool supports unwrap token eg stETH
        uint256 _newSupply = collateralToken.balanceOf(address(this));
        if (_newSupply > 0) {
            _depositToAave(_newSupply, _aaveLendingPool);
        }

        // There are scenarios when we want to call _calculateBorrowPosition and act on it.
        // 1. Strategy got some collateral from pool which will allow strategy to borrow more.
        // 2. Collateral and/or borrow token price is changed which leads to repay or borrow.
        // 3. BorrowLimits are updated.
        // In some edge scenarios, below call is redundant but keeping it as is for simplicity.
        (uint256 _borrowAmount, uint256 _repayAmount) = _calculateBorrowPosition(
            0,
            0,
            vdToken.balanceOf(address(this)),
            IERC20(receiptToken).balanceOf(address(this))
        );
        if (_repayAmount > 0) {
            // Repay _borrowAmount to maintain safe position
            _repayY(_repayAmount, _aaveLendingPool);
        } else if (_borrowAmount > 0) {
            // 2 for variable rate borrow, 0 for referralCode
            _aaveLendingPool.borrow(borrowToken, _borrowAmount, 2, 0, address(this));
        }
        uint256 _borrowTokenBalance = IERC20(borrowToken).balanceOf(address(this));
        if (_borrowTokenBalance > 0) {
            _afterBorrowY(_borrowTokenBalance);
        }
    }

    /// @notice Swap excess borrow for more collateral hook
    function _rebalanceBorrow(uint256 _excessBorrow) internal virtual {}

    function _repayY(uint256 _amount, AaveLendingPool _aaveLendingPool) internal virtual {
        _beforeRepayY(_amount);
        _aaveLendingPool.repay(borrowToken, _amount, 2, address(this));
    }

    /**
     * @dev Swap collateral to borrow token.
     * @param _shortOnBorrow Expected output of this swap
     */
    function _swapToBorrowToken(uint256 _shortOnBorrow, AaveLendingPool _aaveLendingPool) internal {
        // Looking for _amountIn using fixed output amount
        uint256 _amountIn = swapper.getAmountIn(address(wrappedCollateral), borrowToken, _shortOnBorrow);
        if (_amountIn > 0) {
            // Not using unwrapped balance here as those can be used in rebalance reporting via getCollateralHere
            uint256 _collateralHere = wrappedCollateral.balanceOf(address(this));
            if (_amountIn > _collateralHere) {
                // Withdraw some collateral from Aave so that we have enough collateral to get expected output
                uint256 _amount = _amountIn - _collateralHere;
                require(
                    _aaveLendingPool.withdraw(address(wrappedCollateral), _amount, address(this)) == _amount,
                    Errors.INCORRECT_WITHDRAW_AMOUNT
                );
            }
            swapper.swapExactOutput(address(wrappedCollateral), borrowToken, _shortOnBorrow, _amountIn, address(this));
        }
    }

    function _unwrap(uint256 wrappedAmount_) internal virtual returns (uint256) {
        return wrappedAmount_;
    }

    function _wrap(uint256 unwrappedAmount_) internal virtual returns (uint256) {
        return unwrappedAmount_;
    }

    /// @dev If pool supports unwrapped token(stETH) then input and output both are unwrapped token amount.
    function _withdrawHere(uint256 _requireAmount) internal override {
        _withdrawHere(
            _requireAmount,
            AaveLendingPool(aaveAddressProvider.getPool()),
            vdToken.balanceOf(address(this)),
            IERC20(receiptToken).balanceOf(address(this))
        );
    }

    /// @dev If pool supports unwrapped token(stETH) then _requireAmount and output both are unwrapped token amount.
    function _withdrawHere(
        uint256 _requireAmount,
        AaveLendingPool _aaveLendingPool,
        uint256 _borrowed,
        uint256 _supplied
    ) internal {
        uint256 _wrappedRequireAmount = _calculateWrapped(_requireAmount);
        (, uint256 _repayAmount) = _calculateBorrowPosition(0, _wrappedRequireAmount, _borrowed, _supplied);
        if (_repayAmount > 0) {
            _repayY(_repayAmount, _aaveLendingPool);
        }
        // withdraw asking more than available liquidity will fail. To do safe withdraw, check
        // _wrappedRequireAmount against available liquidity.
        uint256 _possibleWithdraw = Math.min(
            _wrappedRequireAmount,
            Math.min(IERC20(receiptToken).balanceOf(address(this)), wrappedCollateral.balanceOf(receiptToken))
        );
        require(
            _aaveLendingPool.withdraw(address(wrappedCollateral), _possibleWithdraw, address(this)) ==
                _possibleWithdraw,
            Errors.INCORRECT_WITHDRAW_AMOUNT
        );
        // Unwrap wrapped tokens
        _unwrap(wrappedCollateral.balanceOf(address(this)));
    }

    /************************************************************************************************
     *                          Governor/admin/keeper function                                      *
     ***********************************************************************************************/
    /**
     * @notice Update upper and lower borrow limit. Usually maxBorrowLimit < 100% of actual collateral factor of protocol.
     * @dev It is possible to set _maxBorrowLimit and _minBorrowLimit as 0 to not borrow anything
     * @param _minBorrowLimit It is % of actual collateral factor of protocol
     * @param _maxBorrowLimit It is % of actual collateral factor of protocol
     */
    function updateBorrowLimit(uint256 _minBorrowLimit, uint256 _maxBorrowLimit) external onlyGovernor {
        require(_maxBorrowLimit < MAX_BPS, "invalid-max-borrow-limit");
        // set _maxBorrowLimit and _minBorrowLimit to disable borrow;
        require(
            (_maxBorrowLimit == 0 && _minBorrowLimit == 0) || _maxBorrowLimit > _minBorrowLimit,
            "max-should-be-higher-than-min"
        );
        emit UpdatedBorrowLimit(minBorrowLimit, _minBorrowLimit, maxBorrowLimit, _maxBorrowLimit);
        minBorrowLimit = _minBorrowLimit;
        maxBorrowLimit = _maxBorrowLimit;
    }
}