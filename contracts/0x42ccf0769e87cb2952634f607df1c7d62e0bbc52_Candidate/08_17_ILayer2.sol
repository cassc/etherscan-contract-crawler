// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface ILayer2 {
  function operator() external view returns (address);
  function isLayer2() external view returns (bool);
  function currentFork() external view returns (uint256);
  function lastEpoch(uint256 forkNumber) external view returns (uint256);
  function changeOperator(address _operator) external;
}