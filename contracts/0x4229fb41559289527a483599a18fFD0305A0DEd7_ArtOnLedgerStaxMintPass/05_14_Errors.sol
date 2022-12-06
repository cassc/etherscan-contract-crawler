// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

library Errors {
    error TokenDoesNotExist();
    error OnlyRootContract();
    error InvalidBaseURI();
    error InvalidBaseContractURL();
    error InvalidOwner();

    /* ReentrancyGuard.sol */
    error ContractLocked();
}