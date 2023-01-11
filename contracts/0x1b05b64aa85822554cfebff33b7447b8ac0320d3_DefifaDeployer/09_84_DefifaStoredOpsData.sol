// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol';

/**
  @member terminal The payment terminal where funds are being accepted through.
  @member distributionLimit The amount that is permitted to be distributed from the terminal.
  @member holdFees A flag indicating if fees should be held from distribution.
*/
struct DefifaStoredOpsData {
  IJBPaymentTerminal terminal;
  uint88 distributionLimit;
  bool holdFees;
}