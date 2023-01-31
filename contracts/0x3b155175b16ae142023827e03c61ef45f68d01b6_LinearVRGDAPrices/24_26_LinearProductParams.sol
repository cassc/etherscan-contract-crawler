// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LinearVRGDAParams } from "./LinearVRGDAParams.sol";

/// @param startTime Time when the VRGDA began.
/// @param startUnits Units available at the time when product is set up.
/// @param decayConstant Precomputed constant that allows us to rewrite a pow() as an exp().
/// @param pricingParams See `LinearVRGDAParams`
struct LinearProductParams {
  uint40 startTime;
  uint32 startUnits;
  int184 decayConstant;
  mapping(address => LinearVRGDAParams) pricingParams;
}