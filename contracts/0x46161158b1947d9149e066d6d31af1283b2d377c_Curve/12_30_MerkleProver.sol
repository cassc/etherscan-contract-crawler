// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./30_30_MerkleProof.sol";

contract MerkleProver {
    bytes32 public immutable merkleRoot = bytes32(0xf4dbd0fb1957570029a847490cb3d731a45962072953ba7da80ff132ccd97d51);

    function isWhitelisted(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public view returns (bool) {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        return MerkleProof.verify(merkleProof, merkleRoot, node);
    }
}