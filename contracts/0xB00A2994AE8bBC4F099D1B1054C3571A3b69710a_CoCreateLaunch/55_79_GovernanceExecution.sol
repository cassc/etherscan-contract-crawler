// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";

contract GovernanceExecution is TimelockControllerUpgradeable {
  function initialize(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors
  ) public initializer {
    __TimelockController_init(minDelay, proposers, executors);
  }
}