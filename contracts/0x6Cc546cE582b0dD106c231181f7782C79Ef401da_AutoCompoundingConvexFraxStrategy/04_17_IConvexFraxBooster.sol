// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IConvexFraxBooster {
  function createVault(uint256 _pid) external returns (address);
}