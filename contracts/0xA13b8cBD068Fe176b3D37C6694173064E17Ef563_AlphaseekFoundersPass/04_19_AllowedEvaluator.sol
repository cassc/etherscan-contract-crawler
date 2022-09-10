// SPDX-License-Identifier: CC0
// Copyright (c) 2022 unReal Accelerator, LLC (https://unrealaccelerator.io)
pragma solidity ^0.8.9;

/// @title: AllowedEvaluator
/// @author: [email protected]
/// @notice Merkle Proof for allow list implementations

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AllowedEvaluator {
    bytes32 internal _allowedMerkleRoot;

    function _setAllowedMerkleRoot(bytes32 allowedMerkleRoot_) internal {
        _allowedMerkleRoot = allowedMerkleRoot_;
    }

    function _validateMerkleProof(address to, bytes32[] calldata merkleProof)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                _allowedMerkleRoot,
                keccak256(abi.encodePacked(to))
            );
    }
}