// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../../ext-contracts/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract MerkleVerifier {
    error MerkleVerificationEror();

    function verifyMerkle(
        bytes32 leaf,
        bytes32[] calldata merkleProof,
        bytes32 merkleRootHash
    ) internal pure {
        if (!MerkleProof.verifyCalldata(merkleProof, merkleRootHash, leaf))
            revert MerkleVerificationEror();
    }

    function isMerkleValid(
        bytes32 leaf,
        bytes32[] calldata merkleProof,
        bytes32 merkleRootHash
    ) internal pure returns(bool) {
        return MerkleProof.verifyCalldata(merkleProof, merkleRootHash, leaf);
    }
}