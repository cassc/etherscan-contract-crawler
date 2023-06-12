// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @custom:member pauseTransfers A flag indicating if the token transfer functionality should be paused during the funding cycle.
/// @custom:member pauseMintingReserves A flag indicating if voting unit expectations can change over time by adding new tiers with voting units.
struct JBTiered721FundingCycleMetadata {
    bool pauseTransfers;
    bool pauseMintingReserves;
}