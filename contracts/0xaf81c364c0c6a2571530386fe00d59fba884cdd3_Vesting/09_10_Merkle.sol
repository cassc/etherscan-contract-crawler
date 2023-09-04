//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Merkle
 * @author gotbit
 */
import 'hardhat/console.sol';

library Merkle {
    /// @dev verifies ogs
    /// @param proof array of bytes for merkle tree verifing
    /// @param root tree's root
    /// @param leaf keccak256 of user address
    ///
    /// @return isCorrect bool Indicator of the correctness of the proof
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isCorrect) {
        bytes32 hash = leaf;
        uint256 length = proof.length;

        for (uint256 i; i < length; ++i) {
            bytes32 proofElement = proof[i];
            hash = hash < proofElement
                ? keccak256(abi.encode(hash, proofElement))
                : keccak256(abi.encode(proofElement, hash));
        }

        return hash == root;
    }
}

/*
library Merkle {
    /// @dev verifies ogs
    /// @param proof array of bytes for merkle tree verifing
    /// @param root tree's root
    /// @param leaf keccak256 of user address
    ///
    /// @return isCorrect bool Indicator of the correctness of the proof
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf,
        uint256 index
    ) public pure returns (bool) {
        bytes32 hash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }

            index = index / 2;
        }

        return hash == root;
    }
}
*/