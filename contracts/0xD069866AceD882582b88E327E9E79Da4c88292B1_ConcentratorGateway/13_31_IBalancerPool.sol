// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IBalancerPool {
  function getPoolId() external view returns (bytes32);
}