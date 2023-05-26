// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRewards {
  function getRewardTokens() external view returns (address[] memory);
  function addRewards(address token, uint256 amount) external;
}