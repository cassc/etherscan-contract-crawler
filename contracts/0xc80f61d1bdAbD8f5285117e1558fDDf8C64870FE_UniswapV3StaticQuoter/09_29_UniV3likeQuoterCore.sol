// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol';
import '@uniswap/v3-core/contracts/libraries/LiquidityMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint128.sol';
import '@uniswap/v3-core/contracts/libraries/SafeCast.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/SwapMath.sol';
import './IUniV3likeQuoterCore.sol';


abstract contract UniV3likeQuoterCore {
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;

    function quote(
        address poolAddress,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) public virtual view returns (int256 amount0, int256 amount1) {
        require(amountSpecified != 0, 'amountSpecified cannot be zero');
        bool exactInput = amountSpecified > 0;
        (int24 tickSpacing, uint16 fee, SwapState memory state) = getInitState(
            poolAddress,
            zeroForOne,
            amountSpecified,
            sqrtPriceLimitX96
        );
        // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            StepComputations memory step;
            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized, step.sqrtPriceNextX96) = nextInitializedTickAndPrice(
                poolAddress,
                state.tick,
                tickSpacing,
                zeroForOne
            );
            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                getSqrtRatioTargetX96(zeroForOne, step.sqrtPriceNextX96, sqrtPriceLimitX96),
                state.liquidity,
                state.amountSpecifiedRemaining,
                fee
            );
            if (exactInput) {
                state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
                state.amountCalculated = state.amountCalculated.sub(step.amountOut.toInt256());
            } else {
                state.amountSpecifiedRemaining += step.amountOut.toInt256();
                state.amountCalculated = state.amountCalculated.add((step.amountIn + step.feeAmount).toInt256());
            }
            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, run the tick transition
                if (step.initialized) {
                    (,int128 liquidityNet,,,,,,) = getTicks(poolAddress, step.tickNext);
                    // if we're moving leftward, we interpret liquidityNet as the opposite sign
                    // safe because liquidityNet cannot be type(int128).min
                    if (zeroForOne)
                        liquidityNet = -liquidityNet;
                    state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityNet);
                }
                state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        (amount0, amount1) = zeroForOne == exactInput
            ? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
            : (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);
    }

    function getInitState(
        address poolAddress,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96
    ) internal view returns (int24 ts, uint16 fee, SwapState memory state) {
        GlobalState memory gs = getPoolGlobalState(poolAddress);
        checkSqrtPriceLimitWithinAllowed(zeroForOne, sqrtPriceLimitX96, gs.startPrice);
        ts = getTickSpacing(poolAddress);
        fee = gs.fee;
        state = SwapState({
            amountSpecifiedRemaining: amountSpecified,
            liquidity: getLiquidity(poolAddress),
            sqrtPriceX96: gs.startPrice,
            amountCalculated: 0,
            tick: gs.startTick
        });
    }

    function checkSqrtPriceLimitWithinAllowed(
        bool zeroForOne,
        uint160 sqrtPriceLimit, 
        uint160 startPrice
    ) internal pure {
        bool withinAllowed = zeroForOne
            ? sqrtPriceLimit < startPrice && sqrtPriceLimit > TickMath.MIN_SQRT_RATIO
            : sqrtPriceLimit > startPrice && sqrtPriceLimit < TickMath.MAX_SQRT_RATIO;
        require(withinAllowed, 'sqrtPriceLimit out of bounds');
    }

    function nextInitializedTickAndPrice(
        address pool, 
        int24 tick, 
        int24 tickSpacing,
        bool zeroForOne
    ) internal view returns (int24 tickNext, bool initialized, uint160 sqrtPriceNextX96) {
        (tickNext, initialized) = nextInitializedTickWithinOneWord(pool, tick, tickSpacing, zeroForOne);
        // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
        if (tickNext < TickMath.MIN_TICK)
            tickNext = TickMath.MIN_TICK;
        else if (tickNext > TickMath.MAX_TICK)
            tickNext = TickMath.MAX_TICK;
        // get the price for the next tick
        sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(tickNext);
    }

    function getSqrtRatioTargetX96(
        bool zeroForOne,
        uint160 sqrtPriceNextX96,
        uint160 sqrtPriceLimitX96
    ) internal pure returns (uint160) {
        return (zeroForOne ? sqrtPriceNextX96<sqrtPriceLimitX96 : sqrtPriceNextX96>sqrtPriceLimitX96)
            ? sqrtPriceLimitX96
            : sqrtPriceNextX96;
    }

    function getPoolGlobalState(address pool) internal virtual view returns (GlobalState memory);
    
    function getLiquidity(address pool) internal virtual view returns (uint128);

    function getTickSpacing(address pool) internal virtual view returns (int24);
    
    function nextInitializedTickWithinOneWord(
        address poolAddress,
        int24 tick,
        int24 tickSpacing,
        bool zeroForOne
    ) internal virtual view returns (int24 next, bool initialized);
    
    function getTicks(address pool, int24 tick) internal virtual view returns (
        uint128 liquidityTotal,
        int128 liquidityDelta,
        uint256 outerFeeGrowth0Token,
        uint256 outerFeeGrowth1Token,
        int56 outerTickCumulative,
        uint160 outerSecondsPerLiquidity,
        uint32 outerSecondsSpent,
        bool initialized
    );

}