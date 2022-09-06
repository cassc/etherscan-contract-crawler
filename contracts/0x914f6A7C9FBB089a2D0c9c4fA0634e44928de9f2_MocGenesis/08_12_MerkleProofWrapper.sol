// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleProofWrapper is Ownable{
    bytes32 public merkleRoot;

    function merkleSetRoot(bytes32 _newRoot) public onlyOwner {
        merkleRoot = _newRoot;
    }

    function merkleVerifySender(bytes32[] memory proof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return merkleVerify(proof, merkleRoot, leaf);
    }

    function merkleVerify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function processProof(bytes32[] memory proof, bytes32 leaf) public pure returns (bytes32) {
        return MerkleProof.processProof(proof, leaf);
    }
}