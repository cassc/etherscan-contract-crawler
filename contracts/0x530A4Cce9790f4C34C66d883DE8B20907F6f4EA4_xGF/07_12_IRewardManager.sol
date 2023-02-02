// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRewardManager {
  function xGF() external view returns (address);

  function rewardToken() external returns (address);

  function feed(uint256 _amount) external returns (bool);

  function claim(address _for) external returns (uint256);

  function pendingRewardsOf(address _user) external returns (uint256);

  function lastTokenBalance() external view returns (uint256);

  function checkpointToken() external view returns (uint256);
}