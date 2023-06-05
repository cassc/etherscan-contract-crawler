// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBSplit.sol';

struct DeployBluntDelegateData {
  IJBDirectory directory;
  address projectOwner;
  uint88 hardcap;
  uint88 target;
  bool isTargetUsd;
  bool isHardcapUsd;
  string tokenName;
  string tokenSymbol;
}