// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRewards {
  function increaseStake(address, uint256) external;
  function decreaseStake(address, uint256) external;
  function claimRewards(address) external;
}