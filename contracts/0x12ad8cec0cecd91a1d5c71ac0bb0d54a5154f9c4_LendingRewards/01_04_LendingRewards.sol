// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import './RewardsTracker.sol';

contract LendingRewards is RewardsTracker {
  constructor(address _token) RewardsTracker(_token) {}
}