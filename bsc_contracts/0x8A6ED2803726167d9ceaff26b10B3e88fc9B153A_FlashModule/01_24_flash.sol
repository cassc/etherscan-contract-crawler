// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../interfaces/IBiswapPoolV3.sol";
import "../interfaces/IBiswapFlashCallback.sol";
import "../interfaces/IBiswapCallback.sol";

import "../libraries/Liquidity.sol";
import "../libraries/Point.sol";
import "../libraries/PointBitmap.sol";
import "../libraries/LogPowMath.sol";
import "../libraries/MulDivMath.sol";
import "../libraries/TwoPower.sol";
import "../libraries/LimitOrder.sol";
import "../libraries/SwapMathY2X.sol";
import "../libraries/SwapMathX2Y.sol";
import "../libraries/SwapMathY2XDesire.sol";
import "../libraries/SwapMathX2YDesire.sol";
import "../libraries/TokenTransfer.sol";
import "../libraries/UserEarn.sol";
import "../libraries/State.sol";
import "../libraries/Oracle.sol";
import "../libraries/OrderOrEndpoint.sol";
import "../libraries/MaxMinMath.sol";

contract FlashModule {

    using Liquidity for mapping(bytes32 =>Liquidity.Data);
    using Liquidity for Liquidity.Data;
    using Point for mapping(int24 =>Point.Data);
    using Point for Point.Data;
    using PointBitmap for mapping(int16 =>uint256);
    using LimitOrder for LimitOrder.Data;
    using UserEarn for UserEarn.Data;
    using UserEarn for mapping(bytes32 =>UserEarn.Data);
    using SwapMathY2X for SwapMathY2X.RangeRetState;
    using SwapMathX2Y for SwapMathX2Y.RangeRetState;
    using Oracle for Oracle.Observation[65535];
    using OrderOrEndpoint for mapping(int24 =>int24);

    int24 internal constant LEFT_MOST_PT = -800000;
    int24 internal constant RIGHT_MOST_PT = 800000;

    /// @notice left most point regularized by pointDelta
    int24 public leftMostPt;
    /// @notice right most point regularized by pointDelta
    int24 public rightMostPt;
    /// @notice maximum liquidSum for each point, see points() in IBiswapPoolV3 or library Point
    uint128 public maxLiquidPt;

    /// @notice address of iBiswapFactoryV3
    address public factory;

    /// @notice address of tokenX
    address public tokenX;
    /// @notice address of tokenY
    address public tokenY;
    /// @notice initialize fee amount of this swap pool, 3000 means 0.3%
    uint16 public fee;

    /// @notice minimum number of distance between initialized or limitorder points
    int24 public pointDelta;

    /// @notice The fee growth as a 128-bit fixpoing fees of tokenX collected per 1 liquidity of the pool
    uint256 public feeScaleX_128;
    /// @notice The fee growth as a 128-bit fixpoing fees of tokenY collected per 1 liquidity of the pool
    uint256 public feeScaleY_128;

    uint160 sqrtRate_96;

    /// @notice some values of pool
    /// see library State or IBiswapPoolV3#state for more infomation
    State public state;

    /// @notice the information about a liquidity by the liquidity's key
    mapping(bytes32 =>Liquidity.Data) public liquidities;

    /// @notice 256 packed point (orderOrEndpoint>0) boolean values. See PointBitmap for more information
    mapping(int16 =>uint256) public pointBitmap;

    /// @notice returns infomation of a point in the pool, see Point library of IBiswapPoolV3#poitns for more information
    mapping(int24 =>Point.Data) public points;
    /// @notice infomation about a point whether has limit order and whether as an liquidity's endpoint
    mapping(int24 =>int24) public orderOrEndpoint;
    /// @notice limitOrder info on a given point
    mapping(int24 =>LimitOrder.Data) public limitOrderData;
    /// @notice information about a user's limit order (sell tokenY and earn tokenX)
    mapping(bytes32 => UserEarn.Data) public userEarnX;
    /// @notice information about a user's limit order (sell tokenX and earn tokenY)
    mapping(bytes32 => UserEarn.Data) public userEarnY;
    /// @notice observation data array
    Oracle.Observation[65535] public observations;

    uint256 public totalFeeXCharged;
    uint256 public totalFeeYCharged;

    address private original;

    address private swapModuleX2Y;
    address private swapModuleY2X;
    address private liquidityModule;
    address private limitOrderModule;
    address private flashModule;

    /// @notice percent to charge from miner's fee
    uint24 public feeChargePercent;

    function balanceX() private view returns (uint256) {
        (bool success, bytes memory data) =
            tokenX.staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this)));
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function balanceY() private view returns (uint256) {
        (bool success, bytes memory data) =
            tokenY.staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this)));
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    /// Delegate call implementation for IBiswapPoolV3#flash.
    function flash(
        address recipient,
        uint256 amountX,
        uint256 amountY,
        bytes calldata data
    ) external returns (uint256 actualAmountX, uint256 actualAmountY, uint256 paidX, uint256 paidY) {
        uint128 currentLiquidity = state.liquidity;
        require(currentLiquidity > 0, 'L');

        // even the balance if not enough, the full fees are required to pay
        uint256 feeX = MulDivMath.mulDivCeil(amountX, state.fee, 1e6);
        uint256 feeY = MulDivMath.mulDivCeil(amountY, state.fee, 1e6);
        uint256 balanceXBefore = balanceX();
        uint256 balanceYBefore = balanceY();

        actualAmountX = MaxMinMath.min256(amountX, balanceXBefore);
        actualAmountY = MaxMinMath.min256(amountY, balanceYBefore);

        if (actualAmountX > 0) TokenTransfer.transferToken(tokenX, recipient, actualAmountX);
        if (actualAmountY > 0) TokenTransfer.transferToken(tokenY, recipient, actualAmountY);

        IBiswapFlashCallback(msg.sender).flashCallback(feeX, feeY, data);
        uint256 balanceXAfter = balanceX();
        uint256 balanceYAfter = balanceY();

        require(balanceXBefore + feeX <= balanceXAfter, 'FX');
        require(balanceYBefore + feeY <= balanceYAfter, 'FY');

        paidX = balanceXAfter - balanceXBefore;
        paidY = balanceYAfter - balanceYBefore;

        if (paidX > 0) {
            uint256 chargedFeeAmount = paidX * feeChargePercent / 100;
            totalFeeXCharged += chargedFeeAmount;
            feeScaleX_128 = feeScaleX_128 + MulDivMath.mulDivFloor(paidX - chargedFeeAmount, TwoPower.Pow128, currentLiquidity);
        }
        if (paidY > 0) {
            uint256 chargedFeeAmount = paidY * feeChargePercent / 100;
            totalFeeYCharged += chargedFeeAmount;
            feeScaleY_128 = feeScaleY_128 + MulDivMath.mulDivFloor(paidY - chargedFeeAmount, TwoPower.Pow128, currentLiquidity);
        }

    }
}