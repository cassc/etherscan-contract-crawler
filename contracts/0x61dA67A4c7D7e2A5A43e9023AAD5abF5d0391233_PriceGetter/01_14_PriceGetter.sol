// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./interfaces/IPool.sol";
import "./interfaces/IUniswapV3Factory.sol";
import "./libraries/TickMath.sol";
import "./libraries/SwapMath.sol";
import "./libraries/FixedPoint128.sol";
import "./libraries/LiquidityMath.sol";
import "./libraries/BitMath.sol";
import "./libraries/SafeCast.sol";
import "./libraries/LowGasSafeMath.sol";

contract PriceGetter {
  using LowGasSafeMath for uint256;
  using LowGasSafeMath for int256;
  using SafeCast for uint256;
  using SafeCast for int256;
  IUniswapV3Factory public factory;

  constructor(address _factory) {
    factory = IUniswapV3Factory(_factory);
  }

  function getPrice(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint160 sqrtPriceLimitX96,
    uint24 fee
  ) public view returns (uint256 amountOut) {
    bool zeroForOne = tokenIn < tokenOut;

    IPool pool = IPool(factory.getPool(tokenIn, tokenOut, fee));

    (int256 amount0, int256 amount1) = getSwapAmounts(
      pool,
      zeroForOne,
      amountIn.toInt256(),
      sqrtPriceLimitX96 == 0
        ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
        : sqrtPriceLimitX96
    );

    return uint256(-(zeroForOne ? amount1 : amount0));
  }

  function getSwapAmounts(
    IPool pool,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96
  ) internal view returns (int256 amount0, int256 amount1) {
    Slot0 memory slot0Start = pool.slot0();
    SwapCache memory cache = SwapCache({
      liquidityStart: pool.liquidity(),
      blockTimestamp: uint32(block.timestamp),
      feeProtocol: zeroForOne ? (slot0Start.feeProtocol % 16) : (slot0Start.feeProtocol >> 4),
      secondsPerLiquidityCumulativeX128: 0,
      tickCumulative: 0,
      computedLatestObservation: false
    });

    bool exactInput = amountSpecified > 0;

    SwapState memory state = SwapState({
      amountSpecifiedRemaining: amountSpecified,
      amountCalculated: 0,
      sqrtPriceX96: slot0Start.sqrtPriceX96,
      tick: slot0Start.tick,
      feeGrowthGlobalX128: zeroForOne ? pool.feeGrowthGlobal0X128() : pool.feeGrowthGlobal1X128(),
      protocolFee: 0,
      liquidity: cache.liquidityStart
    });

    // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
    while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
      StepComputations memory step;

      step.sqrtPriceStartX96 = state.sqrtPriceX96;

      (step.tickNext, step.initialized) = nextInitializedTickWithinOneWord(
        pool,
        state.tick,
        pool.tickSpacing(),
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
      (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath
        .computeSwapStep(
          state.sqrtPriceX96,
          (
            zeroForOne
              ? step.sqrtPriceNextX96 < sqrtPriceLimitX96
              : step.sqrtPriceNextX96 > sqrtPriceLimitX96
          )
            ? sqrtPriceLimitX96
            : step.sqrtPriceNextX96,
          state.liquidity,
          state.amountSpecifiedRemaining,
          pool.fee()
        );

      if (exactInput) {
        state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
        state.amountCalculated = state.amountCalculated.sub(step.amountOut.toInt256());
      } else {
        state.amountSpecifiedRemaining += step.amountOut.toInt256();
        state.amountCalculated = state.amountCalculated.add(
          (step.amountIn + step.feeAmount).toInt256()
        );
      }

      // if the protocol fee is on, calculate how much is owed, decrement feeAmount, and increment protocolFee
      if (cache.feeProtocol > 0) {
        uint256 delta = step.feeAmount / cache.feeProtocol;
        step.feeAmount -= delta;
        state.protocolFee += uint128(delta);
      }

      // update global fee tracker
      if (state.liquidity > 0)
        state.feeGrowthGlobalX128 += FullMath.mulDiv(
          step.feeAmount,
          FixedPoint128.Q128,
          state.liquidity
        );

      // shift tick if we reached the next price
      if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
        // if the tick is initialized, run the tick transition
        if (step.initialized) {
          // check for the placeholder value, which we replace with the actual value the first time the swap
          // crosses an initialized tick
          if (!cache.computedLatestObservation) {
            (cache.tickCumulative, cache.secondsPerLiquidityCumulativeX128) = observeSingle(
              pool,
              cache.blockTimestamp,
              0,
              slot0Start.tick,
              slot0Start.observationIndex,
              cache.liquidityStart,
              slot0Start.observationCardinality
            );
            cache.computedLatestObservation = true;
          }
          int128 liquidityNet = pool.ticks(step.tickNext).liquidityNet;          // if we're moving leftward, we interpret liquidityNet as the opposite sign
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
  }

  function nextInitializedTickWithinOneWord(
    IPool pool,
    int24 tick,
    int24 tickSpacing,
    bool lte
  ) internal view returns (int24 next, bool initialized) {
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

  function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
    wordPos = int16(tick >> 8);
    bitPos = uint8(tick % 256);
  }

  function observeSingle(
    IPool pool,
    uint32 time,
    uint32 secondsAgo,
    int24 tick,
    uint16 index,
    uint128 liquidity,
    uint16 cardinality
  ) internal view returns (int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) {
    if (secondsAgo == 0) {
      Observation memory last = pool.observations(index);
      if (last.blockTimestamp != time) last = transform(last, time, tick, liquidity);
      return (last.tickCumulative, last.secondsPerLiquidityCumulativeX128);
    }

    uint32 target = time - secondsAgo;

    (Observation memory beforeOrAt, Observation memory atOrAfter) = getSurroundingObservations(
      pool,
      time,
      target,
      tick,
      index,
      liquidity,
      cardinality
    );

    if (target == beforeOrAt.blockTimestamp) {
      // we're at the left boundary
      return (beforeOrAt.tickCumulative, beforeOrAt.secondsPerLiquidityCumulativeX128);
    } else if (target == atOrAfter.blockTimestamp) {
      // we're at the right boundary
      return (atOrAfter.tickCumulative, atOrAfter.secondsPerLiquidityCumulativeX128);
    } else {
      // we're in the middle
      uint32 observationTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
      uint32 targetDelta = target - beforeOrAt.blockTimestamp;
      return (
        beforeOrAt.tickCumulative +
          ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / observationTimeDelta) *
          targetDelta,
        beforeOrAt.secondsPerLiquidityCumulativeX128 +
          uint160(
            (uint256(
              atOrAfter.secondsPerLiquidityCumulativeX128 -
                beforeOrAt.secondsPerLiquidityCumulativeX128
            ) * targetDelta) / observationTimeDelta
          )
      );
    }
  }

  function getSurroundingObservations(
    IPool pool,
    uint32 time,
    uint32 target,
    int24 tick,
    uint16 index,
    uint128 liquidity,
    uint16 cardinality
  ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
    // optimistically set before to the newest observation
    beforeOrAt = pool.observations(index);

    // if the target is chronologically at or after the newest observation, we can early return
    if (lte(time, beforeOrAt.blockTimestamp, target)) {
      if (beforeOrAt.blockTimestamp == target) {
        // if newest observation equals target, we're in the same block, so we can ignore atOrAfter
        return (beforeOrAt, atOrAfter);
      } else {
        // otherwise, we need to transform
        return (beforeOrAt, transform(beforeOrAt, target, tick, liquidity));
      }
    }

    // now, set before to the oldest observation
    beforeOrAt = pool.observations((index + 1) % cardinality);
    if (!beforeOrAt.initialized) beforeOrAt = pool.observations(0);

    // ensure that the target is chronologically at or after the oldest observation
    require(lte(time, beforeOrAt.blockTimestamp, target), "OLD");

    // if we've reached this point, we have to binary search
    return binarySearch(pool, time, target, index, cardinality);
  }

  function binarySearch(
    IPool pool,
    uint32 time,
    uint32 target,
    uint16 index,
    uint16 cardinality
  ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
    uint256 l = (index + 1) % cardinality; // oldest observation
    uint256 r = l + cardinality - 1; // newest observation
    uint256 i;
    while (true) {
      i = (l + r) / 2;

      beforeOrAt = pool.observations(uint16(i % cardinality));

      // we've landed on an uninitialized tick, keep searching higher (more recently)
      if (!beforeOrAt.initialized) {
        l = i + 1;
        continue;
      }

      atOrAfter = pool.observations(uint16((i + 1) % cardinality));

      bool targetAtOrAfter = lte(time, beforeOrAt.blockTimestamp, target);

      // check if we've found the answer!
      if (targetAtOrAfter && lte(time, target, atOrAfter.blockTimestamp)) break;

      if (!targetAtOrAfter) r = i - 1;
      else l = i + 1;
    }
  }

  function lte(
    uint32 time,
    uint32 a,
    uint32 b
  ) private pure returns (bool) {
    // if there hasn't been overflow, no need to adjust
    if (a <= time && b <= time) return a <= b;

    uint256 aAdjusted = a > time ? a : a + 2**32;
    uint256 bAdjusted = b > time ? b : b + 2**32;

    return aAdjusted <= bAdjusted;
  }

  function transform(
    Observation memory last,
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity
  ) private pure returns (Observation memory) {
    uint32 delta = blockTimestamp - last.blockTimestamp;
    return
      Observation({
        blockTimestamp: blockTimestamp,
        tickCumulative: last.tickCumulative + int56(tick) * delta,
        secondsPerLiquidityCumulativeX128: last.secondsPerLiquidityCumulativeX128 +
          ((uint160(delta) << 128) / (liquidity > 0 ? liquidity : 1)),
        initialized: true
      });
  }
}