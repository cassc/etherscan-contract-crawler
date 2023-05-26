// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

interface IStaking {
  function balanceOf(address account) external view returns (uint256);

  function stake(uint256 amount) external;

  function stakeFor(uint256 amount, address account) external;

  function withdraw(uint256 amount) external;

  function notifyRewardAmount(uint256 reward) external;
}