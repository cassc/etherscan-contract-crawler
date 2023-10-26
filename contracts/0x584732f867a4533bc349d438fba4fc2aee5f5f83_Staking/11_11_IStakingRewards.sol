// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// https://docs.synthetix.io/contracts/source/interfaces/istakingrewards
interface IStakingRewards {
  // Views

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function lastTimeRewardApplicable() external view returns (uint256);

  function rewardPerToken() external view returns (uint256);

  function earned(address account) external view returns (uint256);

  function getRewardForDuration() external view returns (uint256);

  // Mutative
  function stake(uint256 amount) external;

  function withdraw(uint256 amount) external;

  function getReward() external;

  function exit() external;

  function notifyRewardAmount(uint256 reward) external;
}