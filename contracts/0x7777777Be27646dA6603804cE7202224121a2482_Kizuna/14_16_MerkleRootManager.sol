//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @author KirienzoEth for DokiDoki
 * @title Contract for the Kizuna NFTs by DokiDoki
 */
contract MerkleRootManager is Ownable {
  bytes32 public freeMintMerkleRoot;
  bytes32 public whitelistPhase1MerkleRoot;
  bytes32 public whitelistPhase2MerkleRoot;

  function setFreeMintMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    freeMintMerkleRoot = _merkleRoot;
  }

  function setWhitelistPhase1MerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    whitelistPhase1MerkleRoot = _merkleRoot;
  }

  function setWhitelistPhase2MerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    whitelistPhase2MerkleRoot = _merkleRoot;
  }
}