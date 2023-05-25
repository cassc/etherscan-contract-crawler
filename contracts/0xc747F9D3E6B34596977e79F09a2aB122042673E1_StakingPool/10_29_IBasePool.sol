// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IBasePool {
  function distributeRewards(uint256 _amount) external;
}