// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IStakingPoolManager {
  function reward() external view returns (address);

  function rewardPerBlock() external view returns (uint256);
  
  function setRewardPerBlock(uint256 _rewardPerBlock) external;

  function distributeRewards() external;
}