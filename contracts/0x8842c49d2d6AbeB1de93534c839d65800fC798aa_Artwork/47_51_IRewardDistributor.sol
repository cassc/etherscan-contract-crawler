// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IRewardDistributor {
  function updateFees(uint256) external returns (uint256);
}