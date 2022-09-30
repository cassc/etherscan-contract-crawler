// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract MerkleTest {

    bytes32 constant MERKLE_ROOT = 0x6746d1020f165f020b00cc1e00041419c8d6ea28c88d403da7d6dbcc54d6ac97;

    constructor() {}

    function inList(uint domain, bytes32[] calldata merkleProof) external pure returns (bool) {
        
        bytes32 node = keccak256(abi.encode(domain));
        
        return MerkleProof.verifyCalldata(merkleProof, MERKLE_ROOT, node);
    }
}