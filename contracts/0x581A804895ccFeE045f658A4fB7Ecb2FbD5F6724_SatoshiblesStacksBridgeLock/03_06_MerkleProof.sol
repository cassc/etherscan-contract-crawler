// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library MerkleProof {
    /**
     * @dev Verifies a merkle proof for a root and leaf node
     * @param _proof The merkle proof to verify
     * @param _root The merkle root
     * @param _leaf The leaf node
     * @return isVerified True if the merkle proof is verified
     */
    function verify(
        bytes32[] memory _proof,
        bytes32 _root,
        bytes32 _leaf
    )
        internal
        pure
        returns (bool isVerified)
    {
        bytes32 computedHash = _leaf;

        unchecked {
            for (uint256 i = 0; i < _proof.length; i++) {
                bytes32 proofElement = _proof[i];

                if (computedHash <= proofElement) {
                    computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
                } else {
                    computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
                }
            }
        }

        isVerified = computedHash == _root;
    }
}