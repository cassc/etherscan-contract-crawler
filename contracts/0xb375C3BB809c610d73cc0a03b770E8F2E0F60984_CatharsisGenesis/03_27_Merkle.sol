// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Delegated.sol";

contract Merkle is Delegated{
  bytes32 public merkleRoot = "";

  function setMerkleRoot(bytes32 merkleRoot_) external onlyDelegates{
    merkleRoot = merkleRoot_;
  }

  function _isValidProof(bytes32 leaf, bytes32[] memory proof) internal view returns( bool ){
    return MerkleProof.processProof( proof, leaf ) == merkleRoot;
  }
}