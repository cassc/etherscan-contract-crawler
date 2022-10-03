// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @param targetPrice Target price for a product, to be scaled according to sales pace.
/// @param timeScale Time scale controls the steepness of the logistic curve,
/// which affects how quickly we will reach the curve's asymptote.
struct LogisticVRGDAParams {
  int256 targetPrice;
  int256 timeScale;
}