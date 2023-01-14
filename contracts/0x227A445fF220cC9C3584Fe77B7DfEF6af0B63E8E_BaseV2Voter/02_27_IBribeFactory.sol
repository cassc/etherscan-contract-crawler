// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBribeFactory {
  function createBribe(address _registry) external returns (address);

  event BribeCreated(address _bribe);
}