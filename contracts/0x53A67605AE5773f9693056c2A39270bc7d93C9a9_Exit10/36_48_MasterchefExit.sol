// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { AMasterchefBase } from './AMasterchefBase.sol';

contract MasterchefExit is AMasterchefBase {
  constructor(address rewardToken_, uint256 rewardsDuration_) AMasterchefBase(rewardToken_, rewardsDuration_) {}

  event UpdateRewards(address indexed caller, uint256 amount);

  function updateRewards(uint256 amount) external override onlyOwner {
    require(totalAllocPoint != 0, 'Masterchef: Must initiate a pool before updating rewards');
    require(IERC20(REWARD_TOKEN).balanceOf(address(this)) >= amount, 'MasterchefExit: Token balance not sufficient');
    _updateUndistributedRewards(amount);
    emit UpdateRewards(msg.sender, amount, rewardRate, periodFinish);
  }
}