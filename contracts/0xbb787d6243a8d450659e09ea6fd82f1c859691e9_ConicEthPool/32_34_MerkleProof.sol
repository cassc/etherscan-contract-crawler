// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

library MerkleProof {
    struct Proof {
        uint16 nodeIndex;
        bytes32[] hashes;
    }

    function isValid(
        Proof memory proof,
        bytes32 node,
        bytes32 merkleRoot
    ) internal pure returns (bool) {
        uint256 length = proof.hashes.length;
        uint16 nodeIndex = proof.nodeIndex;
        for (uint256 i = 0; i < length; i++) {
            if (nodeIndex % 2 == 0) {
                node = keccak256(abi.encodePacked(node, proof.hashes[i]));
            } else {
                node = keccak256(abi.encodePacked(proof.hashes[i], node));
            }
            nodeIndex /= 2;
        }

        return node == merkleRoot;
    }
}