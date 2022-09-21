// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import './FullMath.sol';

uint256 constant TWO_FEE_UNITS = 200_000;
uint256 constant TWO_POW_96 = 2**96;
uint128 constant MIN_LIQUIDITY = 100000;
uint8 constant RES_96 = 96;
uint24 constant BPS = 10000;
uint24 constant FEE_UNITS = 100000;
// it is strictly less than 5% price movement if jumping MAX_TICK_DISTANCE ticks
int24 constant MAX_TICK_DISTANCE = 480;
// max number of tick travel when inserting if data changes
uint256 constant MAX_TICK_TRAVEL = 10;

/// @title Contains helper function to add or remove uint128 liquidityDelta to uint128 liquidity
library LiqDeltaMath {
  function applyLiquidityDelta(
    uint128 liquidity,
    uint128 liquidityDelta,
    bool isAddLiquidity
  ) internal pure returns (uint128) {
    return isAddLiquidity ? liquidity + liquidityDelta : liquidity - liquidityDelta;
  }
}