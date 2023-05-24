// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/libraries/TickMath.sol';

import './interfaces/IKyberQuoterCore.sol';
import './interfaces/IKyberPool.sol';
import './lib/SwapMath.sol';
import './lib/SafeCast.sol';


contract KyberQuoterCore {
    using SafeCast for uint256;
    using SafeCast for int128;

    function quote(
        address poolAddress,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) public view returns (int256 amount0, int256 amount1) {
        require(amountSpecified != 0, 'amountSpecified cannot be zero');

        SwapData memory swapData;
        swapData.specifiedAmount = amountSpecified;
        swapData.isToken0 = zeroForOne;
        swapData.isExactInput = swapData.specifiedAmount > 0;
        // tick (token1Qty/token0Qty) will increase for swapping from token1 to token0
        bool willUpTick = (swapData.isExactInput != zeroForOne);
        (
            swapData.baseL,
            swapData.reinvestL,
            swapData.sqrtP,
            swapData.currentTick,
            swapData.nextTick
        ) = getInitialSwapData(poolAddress, willUpTick);
        checkSqrtPriceLimitWithinAllowed(willUpTick, sqrtPriceLimitX96, swapData.sqrtP);
        uint24 swapFeeUnits = IKyberPool(poolAddress).swapFeeUnits();

        // continue swapping while specified input/output isn't satisfied or price limit not reached
        while (swapData.specifiedAmount != 0 && swapData.sqrtP != sqrtPriceLimitX96) {
            int24 tempNextTick = getTempNextTick(swapData.currentTick, swapData.nextTick, willUpTick);
            swapData.nextSqrtP = TickMath.getSqrtRatioAtTick(tempNextTick);
            uint160 startSqrtP = swapData.sqrtP;

            // local scope for targetSqrtP, usedAmount, returnedAmount and deltaL
            {
                uint160 targetSqrtP = swapData.nextSqrtP;
                // ensure next sqrtP (and its corresponding tick) does not exceed price limit
                if (willUpTick == (swapData.nextSqrtP > sqrtPriceLimitX96))
                    targetSqrtP = sqrtPriceLimitX96;

                int256 usedAmount;
                int256 returnedAmount;
                uint256 deltaL;
                (usedAmount, returnedAmount, deltaL, swapData.sqrtP) = SwapMath.computeSwapStep(
                    swapData.baseL + swapData.reinvestL,
                    swapData.sqrtP,
                    targetSqrtP,
                    swapFeeUnits,
                    swapData.specifiedAmount,
                    swapData.isExactInput,
                    swapData.isToken0
                );

                swapData.specifiedAmount -= usedAmount;
                swapData.returnedAmount += returnedAmount;
                swapData.reinvestL += deltaL.toUint128();
            }

            if (swapData.sqrtP != swapData.nextSqrtP) {
                if (swapData.sqrtP != startSqrtP) {
                    // update the current tick data in case the sqrtP has changed
                    swapData.currentTick = TickMath.getTickAtSqrtRatio(swapData.sqrtP);
                }
                break;
            }

            swapData.currentTick = willUpTick ? tempNextTick : tempNextTick - 1;
            // if tempNextTick is not next initialized tick
            if (tempNextTick != swapData.nextTick)
                continue;
            (swapData.baseL, swapData.nextTick) = _updateLiquidityAndCrossTick(
                poolAddress,
                swapData.nextTick,
                swapData.baseL,
                willUpTick
            );
        }

        (amount0, amount1) = zeroForOne
            ? (amountSpecified - swapData.specifiedAmount, swapData.returnedAmount)
            : (swapData.returnedAmount, amountSpecified - swapData.specifiedAmount);

    }

    function getInitialSwapData(
        address poolAddress,
        bool willUpTick
    ) internal view returns (
        uint128 baseL,
        uint128 reinvestL,
        uint160 sqrtP,
        int24 currentTick,
        int24 nextTick
    ) {
        (sqrtP, currentTick, nextTick,) = IKyberPool(poolAddress).getPoolState();
        (baseL, reinvestL,) = IKyberPool(poolAddress).getLiquidityState();
        if (willUpTick)
            nextTick = getNextInitializedTick(poolAddress, nextTick);
    }

    function checkSqrtPriceLimitWithinAllowed(
        bool willUpTick,
        uint160 sqrtPriceLimit, 
        uint160 sqrtP
    ) internal pure {
        bool withinAllowed = willUpTick
            ? sqrtPriceLimit > sqrtP && sqrtPriceLimit < TickMath.MAX_SQRT_RATIO
            : sqrtPriceLimit < sqrtP && sqrtPriceLimit > TickMath.MIN_SQRT_RATIO;
        require(withinAllowed, 'sqrtPriceLimit out of bounds');
    }

    function getTempNextTick(
        int24 currentTick, 
        int24 nextTick, 
        bool willUpTick
    ) internal pure returns (int24 tempNextTick) {
        // math calculations work with the assumption that the price diff is capped to 5%
        // since tick distance is uncapped between currentTick and nextTick
        // we use tempNextTick to satisfy our assumption with MAX_TICK_DISTANCE is set to be matched this condition
        tempNextTick = nextTick;
        if (willUpTick && tempNextTick > MAX_TICK_DISTANCE + currentTick)
            tempNextTick = currentTick + MAX_TICK_DISTANCE;
        else if (!willUpTick && tempNextTick < currentTick - MAX_TICK_DISTANCE)
            tempNextTick = currentTick - MAX_TICK_DISTANCE;
    }

    /// @dev Update liquidity net data and do cross tick
    function _updateLiquidityAndCrossTick(
        address poolAddress,
        int24 nextTick,
        uint128 currentLiquidity,
        bool willUpTick
    ) internal view returns (uint128 newLiquidity, int24 newNextTick) {
        (,int128 liquidityNet,,) = IKyberPool(poolAddress).ticks(nextTick);
        if (willUpTick) {
            (,newNextTick) = IKyberPool(poolAddress).initializedTicks(nextTick);
        } else {
            (newNextTick,) = IKyberPool(poolAddress).initializedTicks(nextTick);
            liquidityNet = -liquidityNet;
        }
        newLiquidity = LiqDeltaMath.applyLiquidityDelta(
            currentLiquidity,
            liquidityNet >= 0 ? uint128(liquidityNet) : liquidityNet.revToUint128(),
            liquidityNet >= 0
        );
    }

    function getNextInitializedTick(
        address poolAddress, 
        int24 tick
    ) internal view returns (int24 next) {
        (,next) = IKyberPool(poolAddress).initializedTicks(tick);
    }

}