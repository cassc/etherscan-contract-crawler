// SPDX-License-Identifier: BSD-3

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import './Delegated.sol';

contract Merkle is Delegated{
  bytes32 internal merkleRoot;

  function setMerkleRoot( bytes32 merkleRoot_ ) external onlyOwner{
    merkleRoot = merkleRoot_;
  }

  function verifyProof(bytes32 leaf, bytes32[] memory proof) internal view{
    require( MerkleProof.processProof( proof, leaf ) == merkleRoot, "Merkle Proof verification failed" );
  }
}