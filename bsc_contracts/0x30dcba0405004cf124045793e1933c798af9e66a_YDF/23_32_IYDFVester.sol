// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @dev YDF token vester interface
 */

interface IYDFVester {
  function createVest(address user, uint256 amount) external;
}