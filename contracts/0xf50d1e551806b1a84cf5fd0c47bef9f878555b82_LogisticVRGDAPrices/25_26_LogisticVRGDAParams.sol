// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @param targetPrice Target price for a product, to be scaled according to sales pace.
/// @param min minimum price to be paid for a token, scaled by 1e18
/// @param timeScale Time scale controls the steepness of the logistic curve,
/// which affects how quickly we will reach the curve's asymptote.
struct LogisticVRGDAParams {
  int128 targetPrice;
  uint128 min;
  int256 timeScale;
}