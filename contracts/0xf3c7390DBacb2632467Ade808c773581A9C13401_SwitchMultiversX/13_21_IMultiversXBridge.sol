// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

interface IMultiversXBridge {
  function deposit(address token, uint256 amount, bytes32 dstAddress) external;
}