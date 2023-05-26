// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract Whitelistable is Ownable {
    bytes32 public merkleRoot = "";

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function checkWhitelisted(address to, bytes32 leaf, bytes32[] memory proof) internal view {
        require(keccak256(abi.encodePacked(to)) == leaf, "InvalidMerkleData");
        require(MerkleProof.verify(proof, merkleRoot, leaf), "NotWhitelisted");
    }
}