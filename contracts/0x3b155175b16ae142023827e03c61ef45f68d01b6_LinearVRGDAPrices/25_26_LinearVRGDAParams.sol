// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @param targetPrice Target price for a product, to be scaled according to sales pace.
/// @param min minimum price to be paid for a token, scaled by 1e18
/// @param perTimeUnit The total number of products to target selling every full unit of time.
struct LinearVRGDAParams {
  int128 targetPrice;
  uint128 min;
  int256 perTimeUnit;
}