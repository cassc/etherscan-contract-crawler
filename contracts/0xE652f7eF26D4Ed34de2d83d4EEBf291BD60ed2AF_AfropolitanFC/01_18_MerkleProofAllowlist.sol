// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract MerkleProofAllowlist {
    using ECDSA for bytes32;

    bytes32 private _merkleRoot;

    function _setMerkleRoot(bytes32 _newMerkleRoot) internal {
        _merkleRoot = _newMerkleRoot;
    }

    function _isProofValid(address _target, bytes32[] memory proof) internal view returns (bool) {
        require(_merkleRoot != "", "Merkle Root must be set");

        return MerkleProof.verify(proof, _merkleRoot, keccak256(abi.encodePacked(_target)));
    }
}