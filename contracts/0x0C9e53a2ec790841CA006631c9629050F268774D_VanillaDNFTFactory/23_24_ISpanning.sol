// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright (C) 2022 Spanning Labs Inc.

pragma solidity ^0.8.0;

/**
 * @dev This module provides a number of utility functions and modifiers for
 * interacting with the Spanning Network.
 *
 * It includes:
 *  + Functions abstracting delegate state and methods
 *  + Functions for multi-domain ownership
 *
 * Note: This module is meant to be used through inheritance.
 */
interface ISpanning {
    /**
     * @return bool - true if the contract is a Spanning contract
     */
    function isSpanning() external pure returns (bool);

    /**
     * @return bool - true if a sender is a Spanning Delegate
     */
    function isSpanningCall() external returns (bool);

    /**
     * @dev Updates Delegate's legacy (local) address.
     *
     * @param newDelegateLegacyAddress - Desired address for Spanning Delegate
     */
    function updateDelegate(address newDelegateLegacyAddress) external;

    /**
     * @return bytes32 - Address of current owner
     */
    function owner() external returns (bytes32);

    /**
     * @dev Sets the owner to null, effectively removing contract ownership.
     *
     * Note: It will not be possible to call `onlyOwner` functions anymore
     * Note: Can only be called by the current owner
     */
    function renounceOwnership() external;

    /**
     * @dev Assigns new owner for the contract.
     *
     * Note: Can only be called by the current owner
     *
     * @param newOwnerAddress - Address for desired owner
     */
    function transferOwnership(bytes32 newOwnerAddress) external;

    /**
     * @dev Emitted when an ownership change has occurred.
     *
     * @param previousOwnerAddress - Address for previous owner
     * @param newOwnerAddress - Address for new owner
     */
    event OwnershipTransferred(
        bytes32 indexed previousOwnerAddress,
        bytes32 indexed newOwnerAddress
    );

    /**
     * @dev Emitted when an Delegate endpoint change has occurred.
     *
     * @param delegateLegacyAddress - Address for previous delegate
     * @param newDelegateLegacyAddress - Address for new delegate
     */
    event DelegateUpdated(
        address indexed delegateLegacyAddress,
        address indexed newDelegateLegacyAddress
    );
}