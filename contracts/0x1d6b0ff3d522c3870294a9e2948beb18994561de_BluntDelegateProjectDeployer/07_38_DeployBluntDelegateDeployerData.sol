// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController3_1.sol';

struct DeployBluntDelegateDeployerData {
  IJBController3_1 controller;
  uint48 feeProjectId;
  uint48 projectId;
  uint40 duration;
  address ethAddress;
  address usdcAddress;
  uint16 maxK;
  uint16 minK;
  uint56 upperFundraiseBoundary;
  uint56 lowerFundraiseBoundary;
}