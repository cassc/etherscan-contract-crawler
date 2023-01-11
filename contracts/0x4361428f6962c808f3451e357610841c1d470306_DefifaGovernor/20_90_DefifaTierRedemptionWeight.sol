// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @member id The tier's ID.
  @member redemptionWeight the weight that each token of this tier can redeem for
*/
struct DefifaTierRedemptionWeight {
  uint256 id;
  uint256 redemptionWeight;
}