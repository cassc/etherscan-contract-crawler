// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

error ContractsCannotMint();

abstract contract AccessControl {
  modifier noContracts {
    if(msg.sender != tx.origin) revert ContractsCannotMint();
    _;
  }
}