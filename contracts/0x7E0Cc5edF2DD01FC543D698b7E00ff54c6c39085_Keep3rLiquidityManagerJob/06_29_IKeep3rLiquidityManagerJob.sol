// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import './IKeep3rJob.sol';

interface IKeep3rLiquidityManagerJob is IKeep3rJob {
  event SetKeep3rLiquidityManager(address _keep3rLiquidityManager);

  // Actions by Keeper
  event Worked(address _job, address _keeper, uint256 _credits, bool _workForTokens);

  // Actions forced by Governor
  event ForceWorked(address _job);

  // Setters
  function setKeep3rLiquidityManager(address _keep3rLiquidityManager) external;

  // Getters
  function keep3rLiquidityManager() external returns (address _keep3rLiquidityManager);

  function jobs() external view returns (address[] memory _jobs);

  function workable(address _job) external returns (bool);

  // Keeper actions
  function work(address _job) external returns (uint256 _credits);

  function workForBond(address _job) external returns (uint256 _credits);

  function workForTokens(address _job) external returns (uint256 _credits);

  // Governor keeper bypass
  function forceWork(address _job) external;
}