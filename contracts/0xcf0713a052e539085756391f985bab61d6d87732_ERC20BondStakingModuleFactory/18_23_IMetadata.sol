/*
IMetadata

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.18;

/**
 * @title Metadata interface
 *
 * @notice this defines the metadata library interface for tokenized staking modules
 */
interface IMetadata {
    /**
     * @notice provide the metadata URI for a tokenized staking module position
     * @param module address of staking module
     * @param id position identifier
     * @param data additional encoded data
     */
    function metadata(
        address module,
        uint256 id,
        bytes calldata data
    ) external view returns (string memory);
}