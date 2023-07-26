// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {HISTORICAL_NUM_ROOTS} from "./configuration/AxiomV1Configuration.sol";

/// @title Merkle Tree
/// @notice Helper functions for computing Merkle roots of Merkle trees
library MerkleTree {
    /// @notice Compute the Merkle root of a Merkle tree with HISTORICAL_NUM_ROOTS leaves
    /// @param  leaves The HISTORICAL_NUM_ROOTS leaves of the Merkle tree
    function merkleRoot(bytes32[HISTORICAL_NUM_ROOTS] memory leaves) internal pure returns (bytes32) {
        // we create a new array to avoid mutating `leaves`, which is passed by reference
        // unnecessary if calldata `leaves` is passed in since it is automatically copied to memory
        bytes32[] memory hashes = new bytes32[](HISTORICAL_NUM_ROOTS / 2);
        for (uint256 i = 0; i < HISTORICAL_NUM_ROOTS / 2; i++) {
            hashes[i] = keccak256(abi.encodePacked(leaves[i << 1], leaves[(i << 1) | 1]));
        }
        uint256 len = HISTORICAL_NUM_ROOTS / 4;
        while (len != 0) {
            for (uint256 i = 0; i < len; i++) {
                hashes[i] = keccak256(abi.encodePacked(hashes[i << 1], hashes[(i << 1) | 1]));
            }
            len >>= 1;
        }
        return hashes[0];
    }

    /// @notice Compute the Merkle root of a Merkle tree with 2^depth leaves all equal to bytes32(0x0)
    /// @param depth The depth of the Merkle tree, 0 <= depth < BLOCK_BATCH_DEPTH.
    function getEmptyHash(uint256 depth) internal pure returns (bytes32) {
        // emptyHashes[idx] is the Merkle root of a tree of depth idx with 0's as leaves
        if (depth == 0) {
            return bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
        } else if (depth == 1) {
            return bytes32(0xad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5);
        } else if (depth == 2) {
            return bytes32(0xb4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30);
        } else if (depth == 3) {
            return bytes32(0x21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85);
        } else if (depth == 4) {
            return bytes32(0xe58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344);
        } else if (depth == 5) {
            return bytes32(0x0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d);
        } else if (depth == 6) {
            return bytes32(0x887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968);
        } else if (depth == 7) {
            return bytes32(0xffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83);
        } else if (depth == 8) {
            return bytes32(0x9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af);
        } else if (depth == 9) {
            return bytes32(0xcefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0);
        } else {
            revert("depth must be in range [0, 10)");
        }
    }
}