// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * A Contract designed to verify a given merkle leaf based on the provided merkle root and proof.
 */
contract MerkleProof {
    /**
     * Verifies that a given leaf lives under the provided root based on the proof.
     * @param root - the root of the merkle tree (keccak hash)
     * @param leaf - the leaf you are proving exists in the tree (keccak hash)
     * @param proof - the proof that verifies that the given leaf exists under that root.
     * @return boolean - indicating validity.
     */
    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}