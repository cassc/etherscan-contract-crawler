// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IParrotRewards {
  function claimReward() external;

  function depositRewards(uint256 _amount) external;

  function getShares(address wallet) external view returns (uint256);

  function deposit(uint256 amount) external;

  function withdraw(uint256 amount) external;
}