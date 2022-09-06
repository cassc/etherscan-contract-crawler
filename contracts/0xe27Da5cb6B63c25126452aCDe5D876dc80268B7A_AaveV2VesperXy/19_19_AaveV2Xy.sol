// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "vesper-pools/contracts/interfaces/vesper/IPoolRewards.sol";
import "../../../interfaces/aave/IAave.sol";
import "../../Strategy.sol";
import "./AaveV2Core.sol";

// solhint-disable no-empty-blocks

/// @title Deposit Collateral in Aave and earn interest by depositing borrowed token in a Vesper Pool.
contract AaveV2Xy is Strategy, AaveV2Core {
    using SafeERC20 for IERC20;

    // solhint-disable-next-line var-name-mixedcase
    string public NAME;
    string public constant VERSION = "5.0.0";

    uint256 internal constant MAX_BPS = 10_000; //100%
    uint256 public minBorrowLimit = 7_000; // 70% of actual collateral factor of protocol
    uint256 public maxBorrowLimit = 8_500; // 85% of actual collateral factor of protocol

    uint32 internal constant TWAP_PERIOD = 3600;
    address public rewardToken;
    address public borrowToken;
    AToken public vdToken; // Variable Debt Token
    address internal aBorrowToken;
    event UpdatedBorrowLimit(
        uint256 previousMinBorrowLimit,
        uint256 newMinBorrowLimit,
        uint256 previousMaxBorrowLimit,
        uint256 newMaxBorrowLimit
    );

    constructor(
        address _pool,
        address _swapper,
        address _rewardToken,
        address _receiptToken,
        address _borrowToken,
        string memory _name
    ) Strategy(_pool, _swapper, _receiptToken) AaveV2Core(_receiptToken) {
        NAME = _name;
        rewardToken = _rewardToken;
        (address _aBorrowToken, , address _vdToken) = aaveProtocolDataProvider.getReserveTokensAddresses(_borrowToken);
        vdToken = AToken(_vdToken);
        borrowToken = _borrowToken;
        aBorrowToken = _aBorrowToken;
    }

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == address(aToken) || address(vdToken) == _token || borrowToken == _token;
    }

    /// @notice Returns total collateral locked in the strategy
    function tvl() external view override returns (uint256) {
        return aToken.balanceOf(address(this)) + collateralToken.balanceOf(address(this));
    }

    /// @notice After borrowing Y Hook
    function _afterBorrowY(uint256 _amount) internal virtual {}

    /// @notice Approve all required tokens
    function _approveToken(uint256 _amount) internal virtual override {
        super._approveToken(_amount);
        collateralToken.safeApprove(address(aToken), _amount);
        collateralToken.safeApprove(address(aaveLendingPool), _amount);
        IERC20(borrowToken).safeApprove(address(aaveLendingPool), _amount);
        IERC20(collateralToken).safeApprove(address(swapper), _amount);
        IERC20(rewardToken).safeApprove(address(swapper), _amount);
        IERC20(borrowToken).safeApprove(address(swapper), _amount);
    }

    /**
     * @notice Claim rewardToken and transfer to new strategy
     * @param _newStrategy Address of new strategy.
     */
    function _beforeMigration(address _newStrategy) internal virtual override {
        require(IStrategy(_newStrategy).token() == address(aToken), "wrong-receipt-token");
        _repayY(vdToken.balanceOf(address(this)));
    }

    /// @notice Before repaying Y Hook
    function _beforeRepayY(uint256 _amount) internal virtual {}

    function _borrowY(uint256 _amount) internal virtual {
        if (_amount > 0) {
            // 2 for variable rate borrow, 0 for referralCode
            aaveLendingPool.borrow(borrowToken, _amount, 2, 0, address(this));
            _afterBorrowY(_amount);
        }
    }

    /**
     * @notice Calculate borrow and repay amount based on current collateral and new deposit/withdraw amount.
     * @param _depositAmount deposit amount
     * @param _withdrawAmount withdraw amount
     * @return _borrowAmount borrow more amount
     * @return _repayAmount repay amount to keep ltv within limit
     */
    function _calculateBorrowPosition(uint256 _depositAmount, uint256 _withdrawAmount)
        internal
        view
        returns (uint256 _borrowAmount, uint256 _repayAmount)
    {
        require(_depositAmount == 0 || _withdrawAmount == 0, "all-input-gt-zero");
        uint256 _borrowed = vdToken.balanceOf(address(this));
        // If maximum borrow limit set to 0 then repay borrow
        if (maxBorrowLimit == 0) {
            return (0, _borrowed);
        }
        uint256 _collateral = aToken.balanceOf(address(this));
        // In case of withdraw, _amount can be greater than _supply
        uint256 _hypotheticalCollateral =
            _depositAmount > 0 ? _collateral + _depositAmount : _collateral > _withdrawAmount
                ? _collateral - _withdrawAmount
                : 0;
        if (_hypotheticalCollateral == 0) {
            return (0, _borrowed);
        }
        AaveOracle _aaveOracle = AaveOracle(aaveAddressesProvider_.getPriceOracle());
        // Oracle prices are in 18 decimal
        uint256 _borrowTokenPrice = _aaveOracle.getAssetPrice(borrowToken);
        uint256 _collateralTokenPrice = _aaveOracle.getAssetPrice(address(collateralToken));
        if (_borrowTokenPrice == 0 || _collateralTokenPrice == 0) {
            // Oracle problem. Lets payback all
            return (0, _borrowed);
        }
        // _collateralFactor in 4 decimal. 10_000 = 100%
        (, uint256 _collateralFactor, , , , , , , , ) =
            aaveProtocolDataProvider.getReserveConfigurationData(address(collateralToken));

        // Collateral in base currency based on oracle price and cf;
        uint256 _actualCollateralForBorrow =
            (_hypotheticalCollateral * _collateralFactor * _collateralTokenPrice) /
                (MAX_BPS * (10**IERC20Metadata(address(collateralToken)).decimals()));
        // Calculate max borrow possible in borrow token number
        uint256 _maxBorrowPossible =
            (_actualCollateralForBorrow * (10**IERC20Metadata(address(borrowToken)).decimals())) / _borrowTokenPrice;
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

    /// @notice Deposit collateral in Aave and adjust borrow position
    function _deposit() internal {
        uint256 _collateralBalance = collateralToken.balanceOf(address(this));

        (uint256 _borrowAmount, uint256 _repayAmount) = _calculateBorrowPosition(_collateralBalance, 0);

        if (_repayAmount > 0) {
            // Repay _borrowAmount to maintain safe position
            _repayY(_repayAmount);
            _mint(_collateralBalance);
        } else {
            // Happy path, mint more borrow more
            _mint(_collateralBalance);
            _borrowY(_borrowAmount);
        }
    }

    /// @notice Borrowed Y balance deposited here or elsewhere hook
    function _getInvestedBorrowBalance() internal view virtual returns (uint256) {
        return IERC20(borrowToken).balanceOf(address(this));
    }

    /**
     * @dev Aave support WETH as collateral.
     */
    function _mint(uint256 _amount) internal virtual {
        _deposit(address(collateralToken), _amount);
    }

    /**
     * @notice Generate report for pools accounting and also send profit and any payback to pool.
     * @dev Claim rewardToken and convert to collateral.
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
        uint256 _totalDebt = IVesperPool(pool).totalDebtOf(address(this));

        // Claim rewards and convert to collateral token
        uint256 _aaveAmount = _claimAave();
        if (_aaveAmount > 0) {
            _safeSwapExactInput(rewardToken, address(collateralToken), _aaveAmount);
        }

        uint256 _supply = aToken.balanceOf(address(this));
        uint256 _borrow = vdToken.balanceOf(address(this));

        uint256 _investedBorrowBalance = _getInvestedBorrowBalance();

        // _borrow increases every block. Convert collateral to borrowToken.
        if (_borrow > _investedBorrowBalance) {
            _swapToBorrowToken(_borrow - _investedBorrowBalance);
        } else {
            // When _investedBorrowBalance exceeds _borrow balance from Aave
            // Customize this hook to handle the excess borrowToken for profit
            _rebalanceBorrow(_investedBorrowBalance - _borrow);
        }

        uint256 _collateralHere = collateralToken.balanceOf(address(this));
        uint256 _totalCollateral = _supply + _collateralHere;

        if (_totalCollateral > _totalDebt) {
            _profit = _totalCollateral - _totalDebt;
        } else {
            _loss = _totalDebt - _totalCollateral;
        }
        uint256 _profitAndExcessDebt = _profit + _excessDebt;
        if (_collateralHere < _profitAndExcessDebt) {
            uint256 _totalAmountToWithdraw = Math.min((_profitAndExcessDebt - _collateralHere), _supply);
            if (_totalAmountToWithdraw > 0) {
                _withdrawHere(_totalAmountToWithdraw);
                _collateralHere = collateralToken.balanceOf(address(this));
            }
        }

        // Make sure _collateralHere >= _payback + profit. set actual payback first and then profit
        _payback = Math.min(_collateralHere, _excessDebt);
        _profit = _collateralHere > _payback ? Math.min((_collateralHere - _payback), _profit) : 0;
        IVesperPool(pool).reportEarning(_profit, _loss, _payback);
        _deposit();
    }

    /// @notice Swap excess borrow for more collateral hook
    function _rebalanceBorrow(uint256 _excessBorrow) internal virtual {}

    function _redeemX(uint256 _amount) internal virtual {
        _withdraw(address(collateralToken), address(this), _amount);
    }

    function _repayY(uint256 _amount) internal virtual {
        _beforeRepayY(_amount);
        aaveLendingPool.repay(borrowToken, _amount, 2, address(this));
    }

    /**
     * @notice Swap given token to borrowToken
     * @param _shortOnBorrow Expected output of this swap
     */
    function _swapToBorrowToken(uint256 _shortOnBorrow) internal {
        // Looking for _amountIn using fixed output amount
        uint256 _amountIn = swapper.getAmountIn(address(collateralToken), borrowToken, _shortOnBorrow);
        if (_amountIn > 0) {
            uint256 _collateralHere = collateralToken.balanceOf(address(this));
            // If we do not have enough _from token to get expected output, either get
            // some _from token or adjust expected output.
            if (_amountIn > _collateralHere) {
                // Redeem some collateral, so that we have enough collateral to get expected output
                _redeemX(_amountIn - _collateralHere);
            }
            swapper.swapExactOutput(address(collateralToken), borrowToken, _shortOnBorrow, _amountIn, address(this));
        }
    }

    /// @dev Withdraw collateral here. Do not transfer to pool
    function _withdrawHere(uint256 _requireAmount) internal override {
        (, uint256 _repayAmount) = _calculateBorrowPosition(0, _requireAmount);
        if (_repayAmount > 0) {
            _repayY(_repayAmount);
        }
        // withdraw asking more than available liquidity will fail. To do safe withdraw, check
        // _requireAmount against available liquidity.
        uint256 _possibleWithdraw =
            Math.min(
                _requireAmount,
                Math.min(IERC20(receiptToken).balanceOf(address(this)), collateralToken.balanceOf(receiptToken))
            );
        _redeemX(_possibleWithdraw);
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