// SPDX-License-Identifier: MIT
// Creator: https://cojodi.com

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./AbstractWhitelist.sol";

contract MerkleWhitelist is AbstractWhitelist {
  mapping(address => bool) public whitelistClaimed;

  bytes32 public whitelistMerkleRoot;

  constructor(bytes32 merkleRoot_) {
    whitelistMerkleRoot = merkleRoot_;
  }

  function setWhitelistMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
    whitelistMerkleRoot = merkleRoot_;
  }

  modifier isWhitelisted(bytes32[] calldata merkleProof_) {
    require(isWhitelistSale, "not whitelist sale");
    require(!whitelistClaimed[msg.sender], "whitelist claimed");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(merkleProof_, whitelistMerkleRoot, leaf), "invalid proof");

    // perform mint
    _;

    whitelistClaimed[msg.sender] = true;
  }
}