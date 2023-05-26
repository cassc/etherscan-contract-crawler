// SPDX-License-Identifier: UNLICENSED
// SEE LICENSE IN https://files.altlayer.io/Alt-Research-License-1.md
// Copyright Alt Research Ltd. 2023. All rights reserved.
//
// You acknowledge and agree that Alt Research Ltd. ("Alt Research") (or Alt
// Research's licensors) own all legal rights, titles and interests in and to the
// work, software, application, source code, documentation and any other documents

pragma solidity ^0.8.18;

interface IFinalizer {
    /**********
     * Events *
     **********/
    event SetMerkleRoot(
        address indexed target,
        uint64 indexed nonce,
        bytes32 root,
        address sender
    );

    event Finalized(
        address indexed target,
        uint64 indexed nonce,
        bytes32 indexed root,
        bytes32 leaf,
        address sender
    );

    /********************
     * Public Functions *
     ********************/

    /// @notice Sets a new Merkle root for a given target and nonce.
    /// @dev Can only be called by the MerkleRootAdmin. Emits a SetMerkleRoot event.
    /// @param target The target contract address for which to set the Merkle root.
    /// @param nonce The nonce for which to set the Merkle root.
    /// @param root The new Merkle root.
    function setMerkleRoot(address target, uint64 nonce, bytes32 root) external;

    /// @notice Executes the finalization process.
    /// @dev Can be overridden in derived contracts.
    /// @param target The target contract address for which to execute finalization.
    /// @param nonce The nonce related to the Merkle root.
    /// @param proof The Merkle proof to verify the data.
    /// @param data The data to be finalized.
    /// @dev Merkle Tree
    /// - The tree is shaped as a complete binary tree.
    /// - The leaves are sorted.
    /// - The leaves are the result of ABI encoding a series of values.
    /// - The hash used is Keccak256.
    function executeFinalization(
        address target,
        uint64 nonce,
        bytes32[] calldata proof,
        bytes calldata data
    ) external;
}