// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract FibswapTimeLock is TimelockController {
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors
  ) public TimelockController(minDelay, proposers, executors) {}
}