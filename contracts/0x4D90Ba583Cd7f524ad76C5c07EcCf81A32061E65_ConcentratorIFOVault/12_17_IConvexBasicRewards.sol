// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IConvexBasicRewards {
  function stakeFor(address, uint256) external returns (bool);

  function balanceOf(address) external view returns (uint256);

  function earned(address) external view returns (uint256);

  function withdrawAll(bool) external returns (bool);

  function withdraw(uint256, bool) external returns (bool);

  function withdrawAndUnwrap(uint256, bool) external returns (bool);

  function getReward() external returns (bool);

  function stake(uint256) external returns (bool);
}