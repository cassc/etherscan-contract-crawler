// SPDX-License-Identifier: MIT
//pragma solidity ^0.6.12;
pragma solidity >=0.6.0;

interface StrongPoolInterface {
  function mineFor(address miner, uint256 amount) external;
}