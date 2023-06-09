// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract PVAllowlist {

    modifier whenInAllowlist(uint256 index, uint256 maxAmount, bytes32[] calldata merkleProof, bytes32 merkleRoot) {
        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, maxAmount));

        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );
        _;
    }
}