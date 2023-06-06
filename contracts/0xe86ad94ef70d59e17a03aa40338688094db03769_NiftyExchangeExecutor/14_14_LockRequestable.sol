// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Gemini Trust Company LLC. All Rights Reserved
pragma solidity 0.8.x;


/** @title  A contract for generating unique identifiers
  *
  * @notice  A contract that provides a identifier generation scheme,
  * guaranteeing uniqueness across all contracts that inherit from it,
  * as well as unpredictability of future identifiers.
  *
  * @dev  This contract is intended to be inherited by any contract that
  * implements the callback software pattern for cooperative custodianship.
  *
  * @author  Gemini Trust Company, LLC
  */
abstract contract LockRequestable {

    // MEMBERS
    /// @notice  the count of all invocations of `generateLockId`.
    uint256 public lockRequestCount;

    constructor() {
        lockRequestCount = 0;
    }

    // FUNCTIONS
    /** @notice  Returns a fresh unique identifier.
      *
      * @dev the generation scheme uses three components.
      * First, the blockhash of the previous block.
      * Second, the deployed address.
      * Third, the next value of the counter.
      * This ensure that identifiers are unique across all contracts
      * following this scheme, and that future identifiers are
      * unpredictable.
      *
      * @return  preLockId  a 32-byte unique identifier.
      * @return  lockRequestIdx  index of lock request
      */
    function generatePreLockId() internal returns (bytes32 preLockId, uint256 lockRequestIdx) {
        lockRequestIdx = ++lockRequestCount;
        preLockId = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                address(this),
                lockRequestIdx
            )
        );
    }
}