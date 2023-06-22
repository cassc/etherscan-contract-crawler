// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/utils/cryptography/MerkleProof.sol";

contract AllowList {
    /// @notice Raised when submitted merkle proof is invalid
    error InvalidProof();
    /// @notice Raised when merkle root is not set
    error MerkleRootNotSet();

    /// @notice The merkle root of the allowlist
    bytes32 public merkleRoot;

    /// @notice Verifies a proof of inclusion in the allowlist
    /// @param sender The address to verify
    /// @param proof The proof of inclusion
    function _verifyProof(address sender, uint256 amountAllocated, bytes32[] calldata proof) internal view {
        if (merkleRoot == 0x0) revert MerkleRootNotSet();
        bool verified = MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(sender, amountAllocated)));
        if (!verified) revert InvalidProof();
    }

    /// @notice Sets the merkle root
    /// @param _merkleRoot The new merkle root to use
    function _setMerkleRoot(bytes32 _merkleRoot) internal {
        merkleRoot = _merkleRoot;
    }
}