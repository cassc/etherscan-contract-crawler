// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-721-delegate/contracts/structs/JB721TierParams.sol';

/**
  @member mintDuration The amount of time mints will be open for before the game's start.
  @member refundPeriodDuration The time between the mint period and the start time where mint's are no longer open but refunds are still allowed.
  @member start The timestamp at which the game should start.
  @member end The timestamp at which the game should end.
*/
struct DefifaTimeData {
  uint48 mintDuration;
  uint48 refundPeriodDuration;
  uint48 start;
  uint48 end;
}