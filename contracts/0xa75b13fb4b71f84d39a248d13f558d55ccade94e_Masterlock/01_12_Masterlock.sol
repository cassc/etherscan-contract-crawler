// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { AmasterlockBase } from './AmasterlockBase.sol';
import { IRewardDistributor } from './IRewardDistributor.sol';

contract Masterlock is AmasterlockBase {
  constructor(address rewardToken_, uint256 rewardsDuration_) AmasterlockBase(rewardToken_, rewardsDuration_) {}

  function withdraw(uint256 pid, uint256 amount, uint256 swapAmountOut) external {
    withdraw(pid, amount);
    IRewardDistributor(owner()).updateFees(swapAmountOut);
  }
}