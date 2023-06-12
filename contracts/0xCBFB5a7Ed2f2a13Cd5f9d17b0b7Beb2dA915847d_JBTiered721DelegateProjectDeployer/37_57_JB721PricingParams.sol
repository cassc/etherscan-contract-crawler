// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPrices.sol";
import "./JB721TierParams.sol";

/// @custom:member tiers The tiers to set.
/// @custom:member currency The currency that the tier contribution floors are denoted in.
/// @custom:member decimals The number of decimals included in the tier contribution floor fixed point numbers.
/// @custom:member prices A contract that exposes price feeds that can be used to resolved the value of a contributions that are sent in different currencies. Set to the zero address if payments must be made in `currency`.
struct JB721PricingParams {
    JB721TierParams[] tiers;
    uint48 currency;
    uint48 decimals;
    IJBPrices prices;
}