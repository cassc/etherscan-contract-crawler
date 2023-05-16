// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title An interface for a contract that is capable of deploying Gritti Metathon Events
/// @notice A contract that constructs a pool must implement this to pass arguments to the pool
/// @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
/// of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain
interface IGrittiMetathonDeployer {
    /// @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
    /// @dev Called by the pool constructor to fetch the parameters of the pool
    function parameters()
        external
        view
        returns (
            address factory,
            string memory eventSlug,
            uint256 maxSupply,
            string memory eventName,
            string memory rootHash,
            string memory name,
            string memory symbol,
            string memory baseURI
        );
}