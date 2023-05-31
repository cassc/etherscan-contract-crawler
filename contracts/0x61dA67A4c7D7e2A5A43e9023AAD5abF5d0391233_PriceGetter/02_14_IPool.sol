// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

struct Info {
  // the total position liquidity that references this tick
  uint128 liquidityGross;
  // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
  int128 liquidityNet;
  // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
  // only has relative meaning, not absolute — the value depends on when the tick is initialized
  uint256 feeGrowthOutside0X128;
  uint256 feeGrowthOutside1X128;
  // the cumulative tick value on the other side of the tick
  int56 tickCumulativeOutside;
  // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
  // only has relative meaning, not absolute — the value depends on when the tick is initialized
  uint160 secondsPerLiquidityOutsideX128;
  // the seconds spent on the other side of the tick (relative to the current tick)
  // only has relative meaning, not absolute — the value depends on when the tick is initialized
  uint32 secondsOutside;
  // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
  // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
  bool initialized;
}

struct Observation {
  // the block timestamp of the observation
  uint32 blockTimestamp;
  // the tick accumulator, i.e. tick * time elapsed since the pool was first initialized
  int56 tickCumulative;
  // the seconds per liquidity, i.e. seconds elapsed / max(1, liquidity) since the pool was first initialized
  uint160 secondsPerLiquidityCumulativeX128;
  // whether or not the observation is initialized
  bool initialized;
}

struct ProtocolFees {
  uint128 token0;
  uint128 token1;
}

struct Slot0 {
  // the current price
  uint160 sqrtPriceX96;
  // the current tick
  int24 tick;
  // the most-recently updated index of the observations array
  uint16 observationIndex;
  // the current maximum number of observations that are being stored
  uint16 observationCardinality;
  // the next maximum number of observations to store, triggered in observations.write
  uint16 observationCardinalityNext;
  // the current protocol fee as a percentage of the swap fee taken on withdrawal
  // represented as an integer denominator (1/x)%
  uint8 feeProtocol;
  // whether the pool is locked
  bool unlocked;
}

struct SwapCache {
  // the protocol fee for the input token
  uint8 feeProtocol;
  // liquidity at the beginning of the swap
  uint128 liquidityStart;
  // the timestamp of the current block
  uint32 blockTimestamp;
  // the current value of the tick accumulator, computed only if we cross an initialized tick
  int56 tickCumulative;
  // the current value of seconds per liquidity accumulator, computed only if we cross an initialized tick
  uint160 secondsPerLiquidityCumulativeX128;
  // whether we've computed and cached the above two accumulators
  bool computedLatestObservation;
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
  uint256 feeGrowthGlobalX128;
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

interface IPool {
  function slot0() external view returns (Slot0 memory);

  function liquidity() external view returns (uint128);

  function feeGrowthGlobal0X128() external view returns (uint256);

  function feeGrowthGlobal1X128() external view returns (uint256);

  function tickSpacing() external view returns (int24);

  function fee() external view returns (uint24);

  function protocolFees() external view returns (ProtocolFees memory);

  function tickBitmap(int16) external view returns (uint256);

  function observations(uint256) external view returns (Observation memory);

  function ticks(int24) external view returns (Info memory);
}