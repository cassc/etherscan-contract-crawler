//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

error MerkleAllowlistNotEnabled();
error InvalidMerkleProof();

contract MerkleProofAllowlisting is Ownable {
    using ECDSA for bytes32;

    // The key used to verify allowlist signatures.
    bytes32 public merkleRoot;

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    modifier requiresMerkleProofAllowlist(bytes32[] calldata _merkleProof) {
        if (merkleRoot == 0) revert MerkleAllowlistNotEnabled();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf))
            revert InvalidMerkleProof();
        _;
    }
}