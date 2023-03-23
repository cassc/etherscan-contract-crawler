// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./MulDivMath.sol";
import "./TwoPower.sol";
import "./AmountMath.sol";
import "./State.sol";
import "./MaxMinMath.sol";
import "./Converter.sol";

library SwapMathY2XDesire {

    struct RangeRetState {
        // whether user acquires enough tokenX
        bool finished;
        // actual cost of tokenY to buy tokenX
        uint256 costY;
        // actual amount of tokenX acquired
        uint128 acquireX;
        // final point after this swap
        int24 finalPt;
        // sqrt price on final point
        uint160 sqrtFinalPrice_96;
        // liquidity of tokenX at finalPt
        // if finalPt is not rightPt, liquidityX is meaningless
        uint128 liquidityX;
    }

    function y2XAtPrice(
        uint128 desireX,
        uint160 sqrtPrice_96,
        uint128 currX
    ) internal pure returns (uint128 costY, uint128 acquireX) {
        acquireX = MaxMinMath.min(desireX, currX);
        uint256 l = MulDivMath.mulDivCeil(acquireX, sqrtPrice_96, TwoPower.Pow96);
        // costY should <= uint128.max
        costY = Converter.toUint128(MulDivMath.mulDivCeil(l, sqrtPrice_96, TwoPower.Pow96));
    }

    function y2XAtPriceLiquidity(
        uint128 desireX,
        uint160 sqrtPrice_96,
        uint128 liquidityX
    ) internal pure returns (uint256 costY, uint128 acquireX, uint128 newLiquidityX) {
        uint256 maxTransformLiquidityY = MulDivMath.mulDivCeil(desireX, sqrtPrice_96, TwoPower.Pow96);
        // transformLiquidityY <= liquidityX <= uint128.max
        uint128 transformLiquidityY = uint128(MaxMinMath.min256(maxTransformLiquidityY, liquidityX));
        costY = MulDivMath.mulDivCeil(transformLiquidityY, sqrtPrice_96, TwoPower.Pow96);
        // transformLiquidityY * TwoPower.Pow96 < 2^128 * 2^96 = 2^224 < 2^256
        acquireX = Converter.toUint128(uint256(transformLiquidityY) * TwoPower.Pow96 / sqrtPrice_96);
        newLiquidityX = liquidityX - transformLiquidityY;
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
        uint256 costY;
        uint128 acquireX;
        bool completeLiquidity;
        int24 locPt;
        uint160 sqrtLoc_96;
    }
    
    function y2XRangeComplete(
        Range memory rg,
        uint128 desireX
    ) internal pure returns (
        RangeCompRet memory ret
    ) {
        uint256 maxX = AmountMath.getAmountX(rg.liquidity, rg.leftPt, rg.rightPt, rg.sqrtPriceR_96, rg.sqrtRate_96, false);
        if (maxX <= desireX) {
            // maxX <= desireX <= uint128.max
            ret.acquireX = uint128(maxX);
            ret.costY = AmountMath.getAmountY(rg.liquidity, rg.sqrtPriceL_96, rg.sqrtPriceR_96, rg.sqrtRate_96, true);
            ret.completeLiquidity = true;
            return ret;
        }

        uint256 sqrtPricePrPl_96 = LogPowMath.getSqrtPrice(rg.rightPt - rg.leftPt);
        // rg.sqrtPriceR_96 * 2^96 < 2^160 * 2^96 = 2^256
        uint160 sqrtPricePrM1_96 = uint160(uint256(rg.sqrtPriceR_96) * TwoPower.Pow96 / rg.sqrtRate_96);

        // div must be > 2^96 because, if
        //  div <= 2^96
        //  <=>  sqrtPricePrPl_96 - desireX * (sqrtPriceR_96 - sqrtPricePrM1_96) / liquidity <= 2^96 (here, '/' is div of int)
        //  <=>  desireX >= (sqrtPricePrPl_96 - 2^96) * liquidity / (sqrtPriceR_96 - sqrtPricePrM1_96) 
        //  <=>  desireX >= maxX
        //  will enter the branch above and return
        uint256 div = sqrtPricePrPl_96 - MulDivMath.mulDivFloor(desireX, rg.sqrtPriceR_96 - sqrtPricePrM1_96, rg.liquidity);

        // 1. rg.sqrtPriceR_96 * 2^96 < 2^160 * 2^96 = 2^256
        // 2. sqrtPriceLoc_96 must < rg.sqrtPriceR_96, because div > 2^96
        uint256 sqrtPriceLoc_96 = uint256(rg.sqrtPriceR_96) * TwoPower.Pow96 / div;

        ret.completeLiquidity = false;
        ret.locPt = LogPowMath.getLogSqrtPriceFloor(uint160(sqrtPriceLoc_96));

        ret.locPt = MaxMinMath.max(rg.leftPt, ret.locPt);
        ret.locPt = MaxMinMath.min(rg.rightPt - 1, ret.locPt);
        ret.sqrtLoc_96 = LogPowMath.getSqrtPrice(ret.locPt);

        if (ret.locPt == rg.leftPt) {
            ret.acquireX = 0;
            ret.costY = 0;
            return ret;
        }

        ret.completeLiquidity = false;
        // ret.acquireX <= desireX <= uint128.max
        ret.acquireX = uint128(MaxMinMath.min256(AmountMath.getAmountX(
            rg.liquidity,
            rg.leftPt,
            ret.locPt,
            ret.sqrtLoc_96,
            rg.sqrtRate_96,
            false
        ), desireX));

        ret.costY = AmountMath.getAmountY(
            rg.liquidity,
            rg.sqrtPriceL_96,
            ret.sqrtLoc_96,
            rg.sqrtRate_96,
            true
        );
    }

    /// @notice Compute amount of tokens exchanged during swapY2XDesireY and some amount values (currX, currY, allX) on final point
    ///    after this swap.
    /// @param currentState state values containing (currX, currY, allX) of start point
    /// @param rightPt right most point during this swap
    /// @param sqrtRate_96 sqrt(1.0001)
    /// @param desireX amount of tokenX user wants to buy
    /// @return retState amount of token acquired and some values on final point
    function y2XRange(
        State memory currentState,
        int24 rightPt,
        uint160 sqrtRate_96,
        uint128 desireX
    ) internal pure returns (
        RangeRetState memory retState
    ) {
        retState.costY = 0;
        retState.acquireX = 0;
        retState.finished = false;
        // first, if current point is not all x, we can not move right directly
        bool startHasY = (currentState.liquidityX < currentState.liquidity);
        if (startHasY) {
            (retState.costY, retState.acquireX, retState.liquidityX) = y2XAtPriceLiquidity(desireX, currentState.sqrtPrice_96, currentState.liquidityX);
            if (retState.liquidityX > 0 || retState.acquireX >= desireX) {
                // currX remain, means desire runout
                retState.finished = true;
                retState.finalPt = currentState.currentPoint;
                retState.sqrtFinalPrice_96 = currentState.sqrtPrice_96;
                return retState;
            } else {
                // not finished
                desireX -= retState.acquireX;
                currentState.currentPoint += 1;
                if (currentState.currentPoint == rightPt) {
                    retState.finalPt = currentState.currentPoint;
                    // get fixed sqrt price to reduce accumulated error
                    retState.sqrtFinalPrice_96 = LogPowMath.getSqrtPrice(rightPt);
                    return retState;
                }
                // sqrt(price) + sqrt(price) * (1.0001 - 1) == sqrt(price) * 1.0001
                currentState.sqrtPrice_96 = uint160(
                    uint256(currentState.sqrtPrice_96) +
                    uint256(currentState.sqrtPrice_96) * (uint256(sqrtRate_96) - TwoPower.Pow96) / TwoPower.Pow96
                );
            }
        }
        
        uint160 sqrtPriceR_96 = LogPowMath.getSqrtPrice(rightPt);
        RangeCompRet memory ret = y2XRangeComplete(
            Range({
                liquidity: currentState.liquidity,
                sqrtPriceL_96: currentState.sqrtPrice_96,
                leftPt: currentState.currentPoint,
                sqrtPriceR_96: sqrtPriceR_96,
                rightPt: rightPt,
                sqrtRate_96: sqrtRate_96
            }), 
            desireX
        );
        retState.costY += ret.costY;
        retState.acquireX += ret.acquireX;
        desireX -= ret.acquireX;

        if (ret.completeLiquidity) {
            retState.finished = (desireX == 0);
            retState.finalPt = rightPt;
            retState.sqrtFinalPrice_96 = sqrtPriceR_96;
        } else {
            uint256 locCostY;
            uint128 locAcquireX;
            (locCostY, locAcquireX, retState.liquidityX) = y2XAtPriceLiquidity(desireX, ret.sqrtLoc_96, currentState.liquidity);
            retState.costY += locCostY;
            retState.acquireX += locAcquireX;
            retState.finished = true;
            retState.finalPt = ret.locPt;
            retState.sqrtFinalPrice_96 = ret.sqrtLoc_96;
        }
    }
    
}