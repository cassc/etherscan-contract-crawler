// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBProjectMetadata.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBSplit.sol';
import './DefifaTimeData.sol';

/**
  @member projectMetadata Metadata to associate with the project within a particular domain. This can be updated any time by the owner of the project.
  @member mintDuration The duration of the game's first phase.
  @member refundPeriodDuration The time between the mint period and the start time where mint's are no longer open but refunds are still allowed.
  @member start The timestamp at which the game should start.
  @member end The timestamp at which the game should end.
  @member holdFees A flag indicating if fees should be held when distributing funds during the second funding cycle.
  @member splits Splits to distribute funds between during the game's second phase.
  @member distributionLimit The amount of funds to distribute from the pot during the game's second phase.
  @member terminal A payment terminal to add for the project.
*/
struct DefifaLaunchProjectData {
  JBProjectMetadata projectMetadata;
  uint48 mintDuration;
  uint48 refundPeriodDuration;
  uint48 start;
  uint48 end;
  bool holdFees;
  JBSplit[] splits;
  uint88 distributionLimit;
  IJBPaymentTerminal terminal;
}