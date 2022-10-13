pragma solidity 0.7.6;
pragma abicoder v2;

import "TickMath.sol";
import "BitMath.sol";
import "TickBitmap.sol";
import "SwapMath.sol";
import "FullMath.sol";
import "SqrtPriceMath.sol";
import "LiquidityMath.sol";
import "LowGasSafeMath.sol";
import "SafeCast.sol";


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}


interface IUniswapV3Pool {

    struct Slot0 {
         uint160 sqrtPriceX96;
         int24 tick;
         uint16 observationIndex;
         uint16 observationCardinality;
         uint16 observationCardinalityNext;
         uint8 feeProtocol;
         bool unlocked;
    }

    function slot0() external view returns (Slot0 memory s0);
    function liquidity() external view returns (uint128);
    function ticks(int24 tick) external view returns (
						      uint128 liquidityGross,
						      int128 liquidityNet,
						      uint256 feeGrowthOutside0X128,
						      uint256 feeGrowthOutside1X128,
						      int56 tickCumulativeOutside,
						      uint160 secondsPerLiquidityOutsideX128,
						      uint32 secondsOutside,
						      bool initialized
						      );
    function tickBitmap(int16 wordPosition) external view returns (uint256);
    function tickSpacing() external view returns (int24);
    function fee() external view returns (uint24);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract UniV3Calc {

    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(tick % 256);
    }

    function nextInitializedTickWithinOneWord(
					      address _pool,
					      int24 tick,
					      bool lte
					      ) private view returns (int24 next, bool initialized) {
	IUniswapV3Pool pool = IUniswapV3Pool(_pool);
	int24 tickSpacing = pool.tickSpacing();
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = pool.tickBitmap(wordPos) & mask;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed - int24(bitPos - BitMath.mostSignificantBit(masked))) * tickSpacing
                : (compressed - int24(bitPos)) * tickSpacing;
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = pool.tickBitmap(wordPos) & mask;

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed + 1 + int24(BitMath.leastSignificantBit(masked) - bitPos)) * tickSpacing
                : (compressed + 1 + int24(type(uint8).max - bitPos)) * tickSpacing;
        }
    }

    function _liqNet(IUniswapV3Pool pool, int24 _tickNext) private view returns (int128) {
	uint128 liquidityGross;
	int128 liquidityNet;
	uint256 feeGrowthOutside0X128;
	uint256 feeGrowthOutside1X128;
	int56 tickCumulativeOutside;
	uint160 secondsPerLiquidityOutsideX128;
	uint32 secondsOutside;
	bool initialized;
		    
		    
	(liquidityGross, liquidityNet, feeGrowthOutside0X128, feeGrowthOutside1X128, tickCumulativeOutside, secondsPerLiquidityOutsideX128, secondsOutside, initialized) =  pool.ticks(_tickNext);
	return liquidityNet;
    }


    // the top level state of the swap, the results of which are recorded in storage at the end
    struct SwapState {
        // the amount remaining to be swapped in/out of the input/output asset
        int256 amountSpecifiedRemaining;
        // the amount already swapped out/in of the output/input asset
        int256 amountCalculated;
        // current sqrt(price)
        uint160 sqrtPriceX96;
        // the tick associated with the current price
        int24 tick;
        // the global fee growth of the input token
        // amount of input token paid as protocol fee
        uint128 protocolFee;
        // the current liquidity in range
        uint128 liquidity;
    }

    struct StepComputations {
        // the price at the beginning of the step
        uint160 sqrtPriceStartX96;
        // the next tick to swap to from the current tick in the swap direction
        int24 tickNext;
        // whether tickNext is initialized or not
        bool initialized;
        // sqrt(price) for the next tick (1/0)
        uint160 sqrtPriceNextX96;
        // how much is being swapped in in this step
        uint256 amountIn;
        // how much is being swapped out
        uint256 amountOut;
        // how much fee is being paid in
        uint256 feeAmount;
    }
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;

    function calc_v3_swap(
		  address _pool,
		  bool zeroForOne,
		  int256 amountSpecified,
		  uint160 sqrtPriceLimitX96
		  ) public view returns (int256 amount0, int256 amount1) {
        require(amountSpecified != 0);

	IUniswapV3Pool pool = IUniswapV3Pool(_pool);
	uint24 fee = pool.fee();
	
        IUniswapV3Pool.Slot0 memory slot0Start = pool.slot0() ;

        require(slot0Start.unlocked);
        require(
            zeroForOne
                ? sqrtPriceLimitX96 < slot0Start.sqrtPriceX96 && sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 > slot0Start.sqrtPriceX96 && sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO
        );

        bool exactInput = amountSpecified > 0;

        SwapState memory state =
            SwapState({
                amountSpecifiedRemaining: amountSpecified,
                amountCalculated: 0,
                sqrtPriceX96: slot0Start.sqrtPriceX96,
                tick: slot0Start.tick,
                protocolFee: 0,
                liquidity: pool.liquidity()
            });

        // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;
	    // replace this with function call 
            (step.tickNext, step.initialized) = nextInitializedTickWithinOneWord(
										 _pool,
										 state.tick,
										 zeroForOne
            );

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            // get the price for the next tick
            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (zeroForOne ? step.sqrtPriceNextX96 < sqrtPriceLimitX96 : step.sqrtPriceNextX96 > sqrtPriceLimitX96)
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                fee
            );

            if (exactInput) {
                state.amountSpecifiedRemaining -= int256(step.amountIn + step.feeAmount);
                state.amountCalculated = state.amountCalculated.sub(int256(step.amountOut));
            } else {
                state.amountSpecifiedRemaining += int256(step.amountOut);
                state.amountCalculated = state.amountCalculated.add(int256(step.amountIn + step.feeAmount));
            }

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, run the tick transition
                if (step.initialized) {

		    int128 liquidityNet = _liqNet(pool, step.tickNext);
                    // if we're moving leftward, we interpret liquidityNet as the opposite sign
                    // safe because liquidityNet cannot be type(int128).min
                    if (zeroForOne) liquidityNet = -liquidityNet;

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


	/* if (zeroForOne) { */
	/*     require(uint256(amount1 * -1) < IERC20(pool.token1()).balanceOf(address(this))); */
	/* } else { */
	/*     require(uint256(amount0 * -1) < IERC20(pool.token0()).balanceOf(address(this))); */
	/* } */
	
    }
    
}