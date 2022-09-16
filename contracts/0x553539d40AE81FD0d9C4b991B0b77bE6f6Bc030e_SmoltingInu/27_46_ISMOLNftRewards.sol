// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISMOLNftRewards {
  function claimReward() external;

  function depositRewards(uint256 _amount) external;

  function getShares(address wallet) external view returns (uint256);
}