// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

/**
 * @notice Interface to represent the owner function, which is necessary for OpenSea compatibility
 */
interface IOwnable {
    /**
     * @notice Function to get the contract OWNER
     * @dev This function needs to the compatibility with the OpenSea
     * @return owner address
     */
    function owner() external view returns (address);
}