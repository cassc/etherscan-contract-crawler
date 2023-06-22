/*
IRewardModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Reward module info interface
 *
 * @notice this contract defines the common interface that any reward module info
 * must implement to be compatible with the modular Pool architecture.
 */

interface IRewardModuleInfo {
    /**
     * @notice get all token metadata
     * @param module address of reward module
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
     * @notice generic function to get pending reward balances
     * @param module address of reward module
     * @param account bytes32 account of interest for preview
     * @param shares number of shares that would be used
     * @param data additional encoded data
     * @return estimated reward balances
     */
    function rewards(
        address module,
        bytes32 account,
        uint256 shares,
        bytes calldata data
    ) external view returns (uint256[] memory);
}