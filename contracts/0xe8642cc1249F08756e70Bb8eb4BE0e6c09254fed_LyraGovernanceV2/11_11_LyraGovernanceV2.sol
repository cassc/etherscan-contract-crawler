//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "@aave/governance-v2/contracts/governance/AaveGovernanceV2.sol";

contract LyraGovernanceV2 is AaveGovernanceV2 {
  constructor(
    address governanceStrategy,
    uint256 votingDelay,
    address guardian,
    address[] memory executors
  ) AaveGovernanceV2(governanceStrategy, votingDelay, guardian, executors) {}
}