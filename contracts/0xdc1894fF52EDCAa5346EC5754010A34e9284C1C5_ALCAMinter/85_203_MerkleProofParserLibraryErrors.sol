// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library MerkleProofParserLibraryErrors {
    error InvalidProofMinimumSize(uint256 proofSize);
    error InvalidProofSize(uint256 proofSize);
    error InvalidKeyHeight(uint256 keyHeight);
}