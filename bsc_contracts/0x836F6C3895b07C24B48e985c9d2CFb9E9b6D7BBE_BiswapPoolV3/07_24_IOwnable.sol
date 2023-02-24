// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IOwnable {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}