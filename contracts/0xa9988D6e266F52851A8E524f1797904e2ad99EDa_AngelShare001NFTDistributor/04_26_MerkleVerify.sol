// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract MerkleVerify {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        string memory leafSource
    ) internal pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(leafSource));
        return MerkleProof.verify(proof, root, leaf);
    }
}