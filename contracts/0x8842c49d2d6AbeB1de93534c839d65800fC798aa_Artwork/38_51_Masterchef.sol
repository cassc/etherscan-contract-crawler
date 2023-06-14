// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { AMasterchefBase } from './AMasterchefBase.sol';
import { IRewardDistributor } from './interfaces/IRewardDistributor.sol';

contract Masterchef is AMasterchefBase {
  constructor(address rewardToken_, uint256 rewardsDuration_) AMasterchefBase(rewardToken_, rewardsDuration_) {}

  function withdraw(uint256 pid, uint256 amount, uint256 swapAmountOut) external {
    withdraw(pid, amount);
    IRewardDistributor(owner()).updateFees(swapAmountOut);
  }
}