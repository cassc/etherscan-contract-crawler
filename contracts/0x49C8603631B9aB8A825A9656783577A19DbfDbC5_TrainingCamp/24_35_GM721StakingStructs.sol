// SPDX-License-Identifier: MIT
// GM2 Contracts (last updated v0.0.1)
pragma solidity ^0.8.9;

struct StakedNFT {
  uint256 lastStartedStakedTime;
  uint256 totalStakedTime;
  address whoStake; // address who starts staking
}