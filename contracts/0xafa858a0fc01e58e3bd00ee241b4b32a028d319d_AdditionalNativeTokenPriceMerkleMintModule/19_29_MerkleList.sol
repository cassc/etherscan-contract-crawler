// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {TokenOwnerChecker} from "src/contracts/utils/TokenOwnerChecker.sol";

/**
 * @title MerkleList
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Abstract utility that allows a Module to verify that some data (a Merkle
 * "leaf", such as an address) has a valid proof in a Merkle tree (such as a
 * list of addresses) added by the token owner.
 */
abstract contract MerkleList is TokenOwnerChecker {
    mapping(address => bytes32) public merkleRoot;

    event MerkleRootUpdated(address indexed token, bytes32 indexed root);

    function verifyProof(
        address token,
        bytes32[] calldata merkleProof,
        bytes32 leaf
    ) internal {
        require(
            merkleRoot[token] > 0,
            "MerkleList: Merkle root has not been set"
        );
        bool valid = MerkleProof.verify(merkleProof, merkleRoot[token], leaf);
        require(valid, "MerkleList: Valid proof required");
    }

    /// Set merkle root
    /// @param token Token address
    /// @param root New merkle root
    /// @notice Only available to token owner
    function updateMerkleRoot(address token, bytes32 root)
        external
        onlyTokenOwner(token)
    {
        merkleRoot[token] = root;
        emit MerkleRootUpdated(token, root);
    }
}