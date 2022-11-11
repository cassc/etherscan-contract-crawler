// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.15;

error ContractsCannotMint();

abstract contract AccessControl {
  modifier noContracts {
    if(msg.sender != tx.origin) revert ContractsCannotMint();
    _;
  }
}