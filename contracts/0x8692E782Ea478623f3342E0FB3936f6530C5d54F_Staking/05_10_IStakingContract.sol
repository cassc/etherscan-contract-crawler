// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;

interface IStakingContract {
  function totalUnmintedInterest() external view returns (uint256);
}