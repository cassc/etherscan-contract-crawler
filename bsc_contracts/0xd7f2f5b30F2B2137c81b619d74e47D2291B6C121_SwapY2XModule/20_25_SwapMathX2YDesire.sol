// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./MulDivMath.sol";
import "./TwoPower.sol";
import "./AmountMath.sol";
import "./State.sol";
import "./MaxMinMath.sol";
import "./Converter.sol";

library SwapMathX2YDesire {
    
    // group returned values of x2YRange to avoid stake too deep
    struct RangeRetState {
        // whether user has acquire enough tokenY
        bool finished;
        // actual cost of tokenX to buy tokenY
        uint256 costX;
        // amount of acquired tokenY
        uint128 acquireY;
        // final point after this swap
        int24 finalPt;
        // sqrt price on final point
        uint160 sqrtFinalPrice_96;
        // liquidity of tokenX at finalPt
        uint128 liquidityX;
    }

    function x2YAtPrice(
        uint128 desireY,
        uint160 sqrtPrice_96,
        uint128 currY
    ) internal pure returns (uint128 costX, uint128 acquireY) {
        acquireY = desireY;
        if (acquireY > currY) {
            acquireY = currY;
        }
        uint256 l = MulDivMath.mulDivCeil(acquireY, TwoPower.Pow96, sqrtPrice_96);
        costX = Converter.toUint128(MulDivMath.mulDivCeil(l, TwoPower.Pow96, sqrtPrice_96));
    }

    function mulDivCeil(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        uint256 v = a * b;
        if (v % c == 0) {
            return v / c;
        }
        return v / c + 1;
    }

    function x2YAtPriceLiquidity(
        uint128 desireY,
        uint160 sqrtPrice_96,
        uint128 liquidity,
        uint128 liquidityX
    ) internal pure returns (uint256 costX, uint128 acquireY, uint128 newLiquidityX) {
        uint256 liquidityY = liquidity - liquidityX;
        // desireY * 2^96 <= 2^128 * 2^96 <= 2^224 < 2^256
        uint256 maxTransformLiquidityX = mulDivCeil(uint256(desireY), TwoPower.Pow96, sqrtPrice_96);
        // transformLiquidityX <= liquidityY <= uint128.max
        uint128 transformLiquidityX = uint128(MaxMinMath.min256(maxTransformLiquidityX, liquidityY));
        // transformLiquidityX * 2^96 <= 2^128 * 2^96 <= 2^224 < 2^256
        costX = mulDivCeil(transformLiquidityX, TwoPower.Pow96, sqrtPrice_96);
        // acquireY should not > uint128.max
        uint256 acquireY256 = MulDivMath.mulDivFloor(transformLiquidityX, sqrtPrice_96, TwoPower.Pow96);
        acquireY = Converter.toUint128(acquireY256);
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
        uint256 costX;
        uint128 acquireY;
        bool completeLiquidity;
        int24 locPt;
        uint160 sqrtLoc_96;
    }
    
    function x2YRangeComplete(
        Range memory rg,
        uint128 desireY
    ) internal pure returns (
        RangeCompRet memory ret
    ) {
        uint256 maxY = AmountMath.getAmountY(rg.liquidity, rg.sqrtPriceL_96, rg.sqrtPriceR_96, rg.sqrtRate_96, false);
        if (maxY <= desireY) {
            // maxY <= desireY <= uint128.max
            ret.acquireY = uint128(maxY);
            ret.costX = AmountMath.getAmountX(rg.liquidity, rg.leftPt, rg.rightPt, rg.sqrtPriceR_96, rg.sqrtRate_96, true);
            ret.completeLiquidity = true;
            return ret;
        }
        // 1. desireY * (rg.sqrtRate_96 - 2^96)
        //    < 2^128 * 2^96
        //    = 2 ^ 224 < 2 ^ 256
        // 2. desireY < maxY = rg.liquidity * (rg.sqrtPriceR_96 - rg.sqrtPriceL_96) / (rg.sqrtRate_96 - 2^96)
        // here, '/' means div of int
        // desireY < rg.liquidity * (rg.sqrtPriceR_96 - rg.sqrtPriceL_96) / (rg.sqrtRate_96 - 2^96)
        // => desireY * (rg.sqrtRate_96 - TwoPower.Pow96) / rg.liquidity < rg.sqrtPriceR_96 - rg.sqrtPriceL_96
        // => rg.sqrtPriceR_96 - desireY * (rg.sqrtRate_96 - TwoPower.Pow96) / rg.liquidity > rg.sqrtPriceL_96
        uint160 cl = uint160(uint256(rg.sqrtPriceR_96) - uint256(desireY) * (rg.sqrtRate_96 - TwoPower.Pow96) / rg.liquidity);
        
        ret.locPt = LogPowMath.getLogSqrtPriceFloor(cl) + 1;
        
        ret.locPt = MaxMinMath.min(ret.locPt, rg.rightPt);
        ret.locPt = MaxMinMath.max(ret.locPt, rg.leftPt + 1);
        ret.completeLiquidity = false;

        if (ret.locPt == rg.rightPt) {
            ret.costX = 0;
            ret.acquireY = 0;
            ret.locPt = ret.locPt - 1;
            ret.sqrtLoc_96 = LogPowMath.getSqrtPrice(ret.locPt);
        } else {
            // rg.rightPt - ret.locPt <= 256 * 100
            // sqrtPricePrMloc_96 <= 1.0001 ** 25600 * 2 ^ 96 = 13 * 2^96 < 2^100
            uint160 sqrtPricePrMloc_96 = LogPowMath.getSqrtPrice(rg.rightPt - ret.locPt);
            // rg.sqrtPriceR_96 * TwoPower.Pow96 < 2^160 * 2^96 = 2^256
            uint160 sqrtPricePrM1_96 = uint160(mulDivCeil(rg.sqrtPriceR_96, TwoPower.Pow96, rg.sqrtRate_96));
            // rg.liquidity * (sqrtPricePrMloc_96 - TwoPower.Pow96) < 2^128 * 2^100 = 2^228 < 2^256
            ret.costX = mulDivCeil(rg.liquidity, sqrtPricePrMloc_96 - TwoPower.Pow96, rg.sqrtPriceR_96 - sqrtPricePrM1_96);

            ret.locPt = ret.locPt - 1;
            ret.sqrtLoc_96 = LogPowMath.getSqrtPrice(ret.locPt);

            uint160 sqrtLocA1_96 = uint160(
                uint256(ret.sqrtLoc_96) +
                uint256(ret.sqrtLoc_96) * (uint256(rg.sqrtRate_96) - TwoPower.Pow96) / TwoPower.Pow96
            );
            uint256 acquireY256 = AmountMath.getAmountY(rg.liquidity, sqrtLocA1_96, rg.sqrtPriceR_96, rg.sqrtRate_96, false);
            // ret.acquireY <= desireY <= uint128.max
            ret.acquireY = uint128(MaxMinMath.min256(acquireY256, desireY));
        }
    }

    /// @notice Compute amount of tokens exchanged during swapX2YDesireY and some amount values (currX, currY, allX) on final point
    ///    after this swap.
    /// @param currentState state values containing (currX, currY, allX) of start point
    /// @param leftPt left most point during this swap
    /// @param sqrtRate_96 sqrt(1.0001)
    /// @param desireY amount of Y user wants to buy
    /// @return retState amount of token acquired and some values on final point
    function x2YRange(
        State memory currentState,
        int24 leftPt,
        uint160 sqrtRate_96,
        uint128 desireY
    ) internal pure returns (
        RangeRetState memory retState
    ) {
        retState.costX = 0;
        retState.acquireY = 0;
        retState.finished = false;

        bool currentHasY = (currentState.liquidityX < currentState.liquidity);
        if (currentHasY && (currentState.liquidityX > 0 || leftPt == currentState.currentPoint)) {
            (retState.costX, retState.acquireY, retState.liquidityX) = x2YAtPriceLiquidity(
                desireY, currentState.sqrtPrice_96, currentState.liquidity, currentState.liquidityX
            );
            if (retState.liquidityX < currentState.liquidity || retState.acquireY >= desireY) {
                // remaining desire y is not enough to down current price to price / 1.0001
                // but desire y may remain, so we cannot simply use (retState.acquireY >= desireY)
                retState.finished = true;
                retState.finalPt = currentState.currentPoint;
                retState.sqrtFinalPrice_96 = currentState.sqrtPrice_96;
            } else {
                desireY -= retState.acquireY;
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
                desireY
            );            
            retState.costX += ret.costX;
            desireY -= ret.acquireY;
            retState.acquireY += ret.acquireY;
            if (ret.completeLiquidity) {
                retState.finished = (desireY == 0);
                retState.finalPt = leftPt;
                retState.sqrtFinalPrice_96 = sqrtPriceL_96;
                retState.liquidityX = currentState.liquidity;
            } else {
                // locPt > leftPt
                uint256 locCostX;
                uint128 locAcquireY;
                // trade at locPt
                (locCostX, locAcquireY, retState.liquidityX) = x2YAtPriceLiquidity(
                    desireY, ret.sqrtLoc_96, currentState.liquidity, 0
                );

                retState.costX += locCostX;
                retState.acquireY += locAcquireY;
                retState.finished = true;
                retState.sqrtFinalPrice_96 = ret.sqrtLoc_96;
                retState.finalPt = ret.locPt;
            }
        } else {
            // finishd must be false
            // retState.finished == false;
            retState.finalPt = currentState.currentPoint;
            retState.sqrtFinalPrice_96 = currentState.sqrtPrice_96;
        }
    }

}