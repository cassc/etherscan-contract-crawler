// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISecurityContract {
  function checkBot(bytes32 botHash, address user) external view returns (bool);
}