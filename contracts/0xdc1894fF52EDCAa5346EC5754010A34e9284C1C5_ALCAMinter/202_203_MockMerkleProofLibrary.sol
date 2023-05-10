// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/parsers/MerkleProofParserLibrary.sol";
import "contracts/utils/MerkleProofLibrary.sol";

contract MockMerkleProofLibrary {
    function computeLeafHash(
        bytes32 key,
        bytes32 value,
        uint16 proofHeight
    ) public pure returns (bytes32) {
        return MerkleProofLibrary.computeLeafHash(key, value, proofHeight);
    }

    function verifyInclusion(
        MerkleProofParserLibrary.MerkleProof memory _proof,
        bytes32 root
    ) public pure {
        MerkleProofLibrary.verifyInclusion(_proof, root);
    }

    function verifyNonInclusion(
        MerkleProofParserLibrary.MerkleProof memory _proof,
        bytes32 root
    ) public pure {
        MerkleProofLibrary.verifyNonInclusion(_proof, root);
    }

    function checkProof(
        bytes memory auditPath,
        bytes32 root,
        bytes32 keyHash,
        bytes32 key,
        bytes memory bitmap,
        uint16 proofHeight
    ) public pure returns (bool) {
        return MerkleProofLibrary.checkProof(auditPath, root, keyHash, key, bitmap, proofHeight);
    }
}