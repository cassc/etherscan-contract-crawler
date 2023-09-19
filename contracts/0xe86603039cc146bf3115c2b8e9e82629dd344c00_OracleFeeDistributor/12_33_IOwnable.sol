// SPDX-FileCopyrightText: 2023 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @dev External interface of Ownable.
 */
interface IOwnable {
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);
}