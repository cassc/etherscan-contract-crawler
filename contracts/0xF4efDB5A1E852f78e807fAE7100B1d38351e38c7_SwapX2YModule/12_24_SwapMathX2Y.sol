// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./MulDivMath.sol";
import "./TwoPower.sol";
import "./AmountMath.sol";
import "./State.sol";
import "./MaxMinMath.sol";
import "./Converter.sol";

library SwapMathX2Y {

    // group returned values of x2YRange to avoid stake too deep
    struct RangeRetState {
        // whether user run out of amountX
        bool finished;
        // actual cost of tokenX to buy tokenY
        uint128 costX;
        // amount of acquired tokenY
        uint256 acquireY;
        // final point after this swap
        int24 finalPt;
        // sqrt price on final point
        uint160 sqrtFinalPrice_96;
        // liquidity of tokenX at finalPt
        uint128 liquidityX;
    }

    function x2YAtPrice(
        uint128 amountX,
        uint160 sqrtPrice_96,
        uint128 currY
    ) internal pure returns (uint128 costX, uint128 acquireY) {
        uint256 l = MulDivMath.mulDivFloor(amountX, sqrtPrice_96, TwoPower.Pow96);
        acquireY = Converter.toUint128(MulDivMath.mulDivFloor(l, sqrtPrice_96, TwoPower.Pow96));
        if (acquireY > currY) {
            acquireY = currY;
        }
        l = MulDivMath.mulDivCeil(acquireY, TwoPower.Pow96, sqrtPrice_96);
        uint256 cost = MulDivMath.mulDivCeil(l, TwoPower.Pow96, sqrtPrice_96);
        // costX <= amountX <= uint128.max
        costX = uint128(cost);
    }

    function mulDivCeil(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        uint256 v = a * b;
        if (v % c == 0) {
            return v / c;
        }
        return v / c + 1;
    }

    function x2YAtPriceLiquidity(
        uint128 amountX,
        uint160 sqrtPrice_96,
        uint128 liquidity,
        uint128 liquidityX
    ) internal pure returns (uint128 costX, uint256 acquireY, uint128 newLiquidityX) {
        uint256 liquidityY = uint256(liquidity - liquidityX);
        uint256 maxTransformLiquidityX = MulDivMath.mulDivFloor(amountX, sqrtPrice_96, TwoPower.Pow96);
        // transformLiquidityX <= liquidityY <= uint128.max
        uint128 transformLiquidityX = uint128(MaxMinMath.min256(maxTransformLiquidityX, liquidityY));

        // 1. transformLiquidityX * TwoPower.Pow96 < 2^128 * 2^96 < 2^224 < 2^256
        // 2. transformLiquidityX <= floor(amountX * sqrtPrice_96 / TwoPower.Pow96)
        // ceil(transformLiquidityX * sqrtPrice_96 / TwoPower.Pow96) <=
        // ceil(floor(amountX * sqrtPrice_96 / TwoPower.Pow96) * sqrtPrice_96 / TwoPower.Pow96) <=
        // ceil(amountX * sqrtPrice_96 / TwoPower.Pow96 * sqrtPrice_96 / TwoPower.Pow96) =
        // ceil(amountX) = amountX <= uint128.max
        costX = uint128(mulDivCeil(transformLiquidityX, TwoPower.Pow96, sqrtPrice_96));
        acquireY = MulDivMath.mulDivFloor(transformLiquidityX, sqrtPrice_96, TwoPower.Pow96);
        newLiquidityX = liquidityX + transformLiquidityX;
    }
    
    struct Range {
        uint128 liquidity;
        uint160 sqrtPriceL_96;
        int24 leftPt;
        uint160 sqrtPriceR_96;
        int24 rightPt;
        uint160 sqrtRate_96;
    }
    
    struct RangeCompRet {
        uint128 costX;
        uint256 acquireY;
        bool completeLiquidity;
        int24 locPt;
        uint160 sqrtLoc_96;
    }

    /// @dev Move from rightPt to leftPt, the range is [leftPt, rightPt).
    function x2YRangeComplete(
        Range memory rg,
        uint128 amountX
    ) internal pure returns (
        RangeCompRet memory ret
    ) {
        // rg.sqrtPriceR_96 * 2^96 < 2^160 * 2^96 = 2^256
        uint160 sqrtPricePrM1_96 = uint160(mulDivCeil(rg.sqrtPriceR_96, TwoPower.Pow96, rg.sqrtRate_96));
        uint160 sqrtPricePrMl_96 = LogPowMath.getSqrtPrice(rg.rightPt - rg.leftPt);
        // rg.rightPt - rg.leftPt <= 256 * 100
        // 1.0001 ** 25600 < 13
        // 13 * 2^96 - 2^96 < 2^100
        // rg.liquidity * (sqrtPricePrMl_96 - TwoPower.Pow96) < 2^228 < 2^256
        uint256 maxX = mulDivCeil(rg.liquidity, sqrtPricePrMl_96 - TwoPower.Pow96, rg.sqrtPriceR_96 - sqrtPricePrM1_96);
        if (maxX <= amountX) {
            // maxX <= amountX <= uint128.max
            ret.costX = uint128(maxX);
            ret.acquireY = AmountMath.getAmountY(rg.liquidity, rg.sqrtPriceL_96, rg.sqrtPriceR_96, rg.sqrtRate_96, false);
            ret.completeLiquidity = true;
        } else {
            // we should locate lowest price
            // 1. amountX * (rg.sqrtPriceR_96 - sqrtPricePrM1_96)
            // < maxX * (rg.sqrtPriceR_96 - sqrtPricePrM1_96)
            // < rg.liquidity * (sqrtPricePrMl_96 - TwoPower.Pow96) + (rg.sqrtPriceR_96 - sqrtPricePrM1_96)
            // < 2^228 + 2^160 < 2^256
            // 2. sqrtValue_96 = amountX * (rg.sqrtPriceR_96 - sqrtPricePrM1_96) // rg.liquidity + 2^96
            // <= amountX * (rg.sqrtPriceR_96 - sqrtPricePrM1_96) / rg.liquidity + 2^96
            // <= (maxX - 1) * (rg.sqrtPriceR_96 - sqrtPricePrM1_96) / rg.liquidity + 2^96
            // < rg.liquidity * (sqrtPricePrMl_96 - 2^96) / (rg.sqrtPriceR_96 - sqrtPricePrM1_96) * (rg.sqrtPriceR_96 - sqrtPricePrM1_96) / rg.liquidity + 2^96
            // = sqrtPricePrMl_96 < 2^160
            uint160 sqrtValue_96 = uint160(uint256(amountX) * (uint256(rg.sqrtPriceR_96) - sqrtPricePrM1_96) / uint256(rg.liquidity) + TwoPower.Pow96);

            int24 logValue = LogPowMath.getLogSqrtPriceFloor(sqrtValue_96);

            ret.locPt = rg.rightPt - logValue;

            ret.locPt = MaxMinMath.min(ret.locPt, rg.rightPt);
            ret.locPt = MaxMinMath.max(ret.locPt, rg.leftPt + 1);
            ret.completeLiquidity = false;
            
            if (ret.locPt == rg.rightPt) {
                ret.costX = 0;
                ret.acquireY = 0;
                ret.locPt = ret.locPt - 1;
                ret.sqrtLoc_96 = LogPowMath.getSqrtPrice(ret.locPt);
            } else {
                uint160 sqrtPricePrMloc_96 = LogPowMath.getSqrtPrice(rg.rightPt - ret.locPt);
                // rg.rightPt - ret.locPt <= 256 * 100
                // 1.0001 ** 25600 < 13
                // 13 * 2^96 - 2^96 < 2^100
                // rg.liquidity * (sqrtPricePrMloc_96 - TwoPower.Pow96) < 2^228 < 2^256
                uint256 costX256 = mulDivCeil(rg.liquidity, sqrtPricePrMloc_96 - TwoPower.Pow96, rg.sqrtPriceR_96 - sqrtPricePrM1_96);
                // ret.costX <= amountX <= uint128.max
                ret.costX = uint128(MaxMinMath.min256(costX256, amountX));
                
                ret.locPt = ret.locPt - 1;
                ret.sqrtLoc_96 = LogPowMath.getSqrtPrice(ret.locPt);

                uint160 sqrtLocA1_96 = uint160(
                    uint256(ret.sqrtLoc_96) +
                    uint256(ret.sqrtLoc_96) * (uint256(rg.sqrtRate_96) - TwoPower.Pow96) / TwoPower.Pow96
                );
                ret.acquireY = AmountMath.getAmountY(rg.liquidity, sqrtLocA1_96, rg.sqrtPriceR_96, rg.sqrtRate_96, false);
            }
        }
    }
    
    /// @notice Compute amount of tokens exchanged during swapX2Y and some amount values (currX, currY, allX) on final point
    ///    after this swap.
    /// @param currentState state values containing (currX, currY, allX) of start point
    /// @param leftPt left most point during this swap
    /// @param sqrtRate_96 sqrt(1.0001)
    /// @param amountX max amount of tokenX user willing to pay
    /// @return retState amount of token acquired and some values on final point
    function x2YRange(
        State memory currentState,
        int24 leftPt,
        uint160 sqrtRate_96,
        uint128 amountX
    ) internal pure returns (
        RangeRetState memory retState
    ) {
        retState.costX = 0;
        retState.acquireY = 0;
        retState.finished = false;

        bool currentHasY = (currentState.liquidityX < currentState.liquidity);
        if (currentHasY && (currentState.liquidityX > 0 || leftPt == currentState.currentPoint)) {
            (retState.costX, retState.acquireY, retState.liquidityX) = x2YAtPriceLiquidity(
                amountX, currentState.sqrtPrice_96, currentState.liquidity, currentState.liquidityX
            );
            if (retState.liquidityX < currentState.liquidity ||  retState.costX >= amountX) {
                // remaining x is not enough to down current price to price / 1.0001
                // but x may remain, so we cannot simply use (costX == amountX)
                retState.finished = true;
                retState.finalPt = currentState.currentPoint;
                retState.sqrtFinalPrice_96 = currentState.sqrtPrice_96;
            } else {
                amountX -= retState.costX;
            }
        } else if (currentHasY) { // all y
            currentState.currentPoint = currentState.currentPoint + 1;
            // sqrt(price) + sqrt(price) * (1.0001 - 1) == sqrt(price) * 1.0001
            currentState.sqrtPrice_96 = uint160(
                uint256(currentState.sqrtPrice_96) +
                uint256(currentState.sqrtPrice_96) * (uint256(sqrtRate_96) - TwoPower.Pow96) / TwoPower.Pow96
            );
        } else {
            retState.liquidityX = currentState.liquidityX;
        }

        if (retState.finished) {
            return retState;
        }

        if (leftPt < currentState.currentPoint) {
            uint160 sqrtPriceL_96 = LogPowMath.getSqrtPrice(leftPt);
            RangeCompRet memory ret = x2YRangeComplete(
                Range({
                    liquidity: currentState.liquidity,
                    sqrtPriceL_96: sqrtPriceL_96,
                    leftPt: leftPt, 
                    sqrtPriceR_96: currentState.sqrtPrice_96, 
                    rightPt: currentState.currentPoint, 
                    sqrtRate_96: sqrtRate_96
                }),
                amountX
            );
            retState.costX += ret.costX;
            amountX -= ret.costX;
            retState.acquireY += ret.acquireY;
            if (ret.completeLiquidity) {
                retState.finished = (amountX == 0);
                retState.finalPt = leftPt;
                retState.sqrtFinalPrice_96 = sqrtPriceL_96;
                retState.liquidityX = currentState.liquidity;
            } else {
                uint128 locCostX;
                uint256 locAcquireY;
                (locCostX, locAcquireY, retState.liquidityX) = x2YAtPriceLiquidity(amountX, ret.sqrtLoc_96, currentState.liquidity, 0);
                retState.costX += locCostX;
                retState.acquireY += locAcquireY;
                retState.finished = true;
                retState.sqrtFinalPrice_96 = ret.sqrtLoc_96;
                retState.finalPt = ret.locPt;
            }
        } else {
            // finishd must be false
            // retState.finished == false;
            // liquidityX has been set
            retState.finalPt = currentState.currentPoint;
            retState.sqrtFinalPrice_96 = currentState.sqrtPrice_96;
        }
    }
    
}