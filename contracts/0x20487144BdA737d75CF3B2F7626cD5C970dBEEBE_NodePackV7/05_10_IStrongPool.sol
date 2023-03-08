// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

interface IStrongPool {
  function mineFor(address miner, uint256 amount) external;
}