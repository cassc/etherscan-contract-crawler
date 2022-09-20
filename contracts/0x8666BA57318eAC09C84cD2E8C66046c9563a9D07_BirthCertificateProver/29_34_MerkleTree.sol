/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.0;

/**
 * @title Merkle Tree
 * @author Theori, Inc.
 * @notice Gas optimized SHA256 Merkle tree code.
 */
library MerkleTree {
    /**
     * @notice computes a SHA256 merkle root of the provided hashes, in place
     * @param temp the mutable array of hashes
     * @return the merkle root hash
     */
    function computeRoot(bytes32[] memory temp) internal view returns (bytes32) {
        uint256 count = temp.length;
        assembly {
            // repeat until we arrive at one root hash
            for {

            } gt(count, 1) {

            } {
                let dataElementLocation := add(temp, 0x20)
                let hashElementLocation := add(temp, 0x20)
                for {
                    let i := 0
                } lt(i, count) {
                    i := add(i, 2)
                } {
                    if iszero(
                        staticcall(gas(), 0x2, hashElementLocation, 0x40, dataElementLocation, 0x20)
                    ) {
                        revert(0, 0)
                    }
                    dataElementLocation := add(dataElementLocation, 0x20)
                    hashElementLocation := add(hashElementLocation, 0x40)
                }
                count := shr(1, count)
            }
        }
        return temp[0];
    }

    /**
     * @notice check if a hash is in the merkle tree for rootHash
     * @param rootHash the merkle root
     * @param index the index of the node to check
     * @param hash the hash to check
     * @param proofHashes the proof, i.e. the sequence of siblings from the
     *        node to root
     */
    function validProof(
        bytes32 rootHash,
        uint256 index,
        bytes32 hash,
        bytes32[] memory proofHashes
    ) internal view returns (bool result) {
        assembly {
            let constructedHash := hash
            let length := mload(proofHashes)
            let start := add(proofHashes, 0x20)
            let end := add(start, mul(length, 0x20))
            for {
                let ptr := start
            } lt(ptr, end) {
                ptr := add(ptr, 0x20)
            } {
                let proofHash := mload(ptr)

                // use scratch space (0x0 - 0x40) for hash input
                switch and(index, 1)
                case 0 {
                    mstore(0x0, constructedHash)
                    mstore(0x20, proofHash)
                }
                case 1 {
                    mstore(0x0, proofHash)
                    mstore(0x20, constructedHash)
                }

                // compute sha256
                if iszero(staticcall(gas(), 0x2, 0x0, 0x40, 0x0, 0x20)) {
                    revert(0, 0)
                }
                constructedHash := mload(0x0)

                index := shr(1, index)
            }
            result := eq(constructedHash, rootHash)
        }
    }
}