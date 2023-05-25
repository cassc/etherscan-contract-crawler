// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

library Errors {
    error IdBeyondSupplyLimit();
    error WrongInputSize();
    error TokenDoesNotExist();
    error NotOwner();
    error NotAuthorized();
    error InvalidBaseContractURL();
    error InvalidBaseURI();
    error NewSignerCantBeZero();

    error InvalidOwner();
    error InvalidOwnerSignature();

    /* ReentrancyGuard.sol */
    error ContractLocked();
}