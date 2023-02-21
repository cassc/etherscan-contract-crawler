// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Pausable contract interface
 * @author CloudWalk Inc.
 * @dev Allows to trigger the paused or unpaused state of the contract.
 */
interface IPausable {
    // -------------------- Functions -----------------------------------

    /**
     * @dev Triggers the paused state of the contract.
     */
    function pause() external;

    /**
     * @dev Triggers the unpaused state of the contract.
     */
    function unpause() external;
}