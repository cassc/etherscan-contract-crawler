/*
IModuleFactory

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Module factory interface
 *
 * @notice this defines the common module factory interface used by the
 * main factory to create the staking and reward modules for a new Pool.
 */
interface IModuleFactory {
    // events
    event ModuleCreated(address indexed user, address module);

    /**
     * @notice create a new Pool module
     * @param config address for configuration contract
     * @param data binary encoded construction parameters
     * @return address of newly created module
     */
    function createModule(address config, bytes calldata data)
        external
        returns (address);
}