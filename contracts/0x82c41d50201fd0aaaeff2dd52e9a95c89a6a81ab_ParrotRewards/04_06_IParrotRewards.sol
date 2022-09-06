// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IParrotRewards {
  function claimReward() external;

  function depositRewards() external payable;

  function getLockedShares(address wallet) external view returns (uint256);

  function lock(uint256 amount) external;

  function unlock(uint256 amount) external;
}