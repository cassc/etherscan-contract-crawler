// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @param targetPrice Target price for a product, to be scaled according to sales pace.
/// @param perTimeUnit The total number of products to target selling every full unit of time.
struct LinearVRGDAParams {
  int256 targetPrice;
  int256 perTimeUnit;
}