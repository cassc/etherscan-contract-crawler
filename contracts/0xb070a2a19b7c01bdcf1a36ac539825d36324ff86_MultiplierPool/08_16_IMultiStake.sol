// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface IMultiStake {
  struct Stake {
    // [e18] Staked token amount
    uint256 amount;
    // [seconds] block timestamp at point of stake
    uint256 timestamp;
  }
}