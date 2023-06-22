/*
IStakingModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Staking module info interface
 *
 * @notice this contract defines the common interface that any staking module info
 * must implement to be compatible with the modular Pool architecture.
 */
interface IStakingModuleInfo {
    /**
     * @notice convenience function to get all token metadata in a single call
     * @param module address of staking module
     * @return addresses
     * @return names
     * @return symbols
     * @return decimals
     */
    function tokens(
        address module
    )
        external
        view
        returns (
            address[] memory,
            string[] memory,
            string[] memory,
            uint8[] memory
        );

    /**
     * @notice get all staking positions for user
     * @param module address of staking module
     * @param addr user address of interest
     * @param data additional encoded data
     * @return accounts_
     * @return shares_
     */
    function positions(
        address module,
        address addr,
        bytes calldata data
    ) external view returns (bytes32[] memory, uint256[] memory);
}