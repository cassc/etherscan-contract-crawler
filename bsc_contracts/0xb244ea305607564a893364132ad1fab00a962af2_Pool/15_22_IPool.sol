// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {SignedInt} from "../lib/SignedInt.sol";

enum Side {
    LONG,
    SHORT
}

struct TokenWeight {
    address token;
    uint256 weight;
}

interface IPool {
    function increasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeChanged,
        Side _side
    ) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _desiredCollateralReduce,
        uint256 _sizeChanged,
        Side _side,
        address _receiver
    ) external;

    function liquidatePosition(address _account, address _indexToken, address _collateralToken, Side _side) external;

    function validateToken(address indexToken, address collateralToken, Side side, bool isIncrease)
        external
        view
        returns (bool);

    function swap(address _tokenIn, address _tokenOut, uint256 _minOut, address _to) external;

    function addLiquidity(address _tranche, address _token, uint256 _amountIn, uint256 _minLpAmount, address _to)
        external;

    function removeLiquidity(address _tranche, address _tokenOut, uint256 _lpAmount, uint256 _minOut, address _to)
        external;

    // =========== EVENTS ===========
    event SetOrderManager(address orderManager);
    event IncreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralValue,
        uint256 sizeChanged,
        Side side,
        uint256 indexPrice,
        uint256 feeValue
    );
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount,
        uint256 indexPrice
    );
    event DecreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralChanged,
        uint256 sizeChanged,
        Side side,
        uint256 indexPrice,
        SignedInt pnl,
        uint256 feeValue
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount
    );
    event LiquidatePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        Side side,
        uint256 size,
        uint256 collateralValue,
        uint256 reserveAmount,
        uint256 indexPrice,
        SignedInt pnl,
        uint256 feeValue
    );
    event DaoFeeWithdrawn(address token, address recipient, uint256 amount);
    event DaoFeeReduced(address token, uint256 amount);
    event FeeDistributorSet(address feeDistributor);
    event LiquidityAdded(
        address indexed tranche, address indexed sender, address token, uint256 amount, uint256 lpAmount, uint256 fee
    );
    event LiquidityRemoved(
        address indexed tranche, address indexed sender, address token, uint256 lpAmount, uint256 amountOut, uint256 fee
    );
    event TokenWeightSet(TokenWeight[]);
    event Swap(address sender, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, uint256 fee);
    event PositionFeeSet(uint256 positionFee, uint256 liquidationFee);
    event DaoFeeSet(uint256 value);
    event SwapFeeSet(
        uint256 baseSwapFee, uint256 taxBasisPoint, uint256 stableCoinBaseSwapFee, uint256 stableCoinTaxBasisPoint
    );
    event InterestAccrued(address token, uint256 borrowIndex);
    event MaxLeverageChanged(uint256 maxLeverage);
    event TokenWhitelisted(address token);
    event TokenDelisted(address token);
    event OracleChanged(address oldOracle, address newOracle);
    event InterestRateSet(uint256 interestRate, uint256);
    event MaxPositionSizeSet(uint256 maxPositionSize);
    event PositionHookChanged(address hook);
    event TrancheAdded(address lpToken);
    event TokenRiskFactorUpdated(address token);
    event PnLDistributed(address indexed asset, address indexed tranche, uint256 amount, bool hasProfit);
    event MaintenanceMarginChanged(uint256 ratio);
}