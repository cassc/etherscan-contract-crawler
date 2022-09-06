// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

interface IIdleCDOTrancheRewards {
  function stake(uint256 _amount) external;
  function stakeFor(address _user, uint256 _amount) external;
  function unstake(uint256 _amount) external;
  function depositReward(address _reward, uint256 _amount) external;
}