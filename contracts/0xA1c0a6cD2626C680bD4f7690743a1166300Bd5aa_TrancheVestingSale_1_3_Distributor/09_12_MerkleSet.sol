// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract MerkleSet {
  event InitializeMerkleSet(address account, uint256 amount);

  bytes32 public immutable merkleRoot;
  constructor(bytes32 _merkleRoot) {
    merkleRoot = _merkleRoot;
  }

  function _testMembership(bytes32 leaf, bytes32[] calldata merkleProof)
    internal
    view returns (bool)
  {
    return MerkleProof.verify(merkleProof, merkleRoot, leaf);
  }

  function _verifyMembership(bytes32 leaf, bytes32[] calldata merkleProof)
    internal
    view
  {
    require(_testMembership(leaf, merkleProof), "invalid proof");
  }

  modifier validMerkleProof(
    uint256 index, // the beneficiary's index in the merkle root
    address beneficiary, // the address that will receive tokens
    uint256 amount, // the total claimable by this beneficiary
    bytes32[] calldata merkleProof
  ) {
    // the merkle leaf encodes the total claimable: the amount claimed in this call is determined by _getVestedFraction()
    bytes32 leaf = keccak256(abi.encodePacked(index, beneficiary, amount));
    _verifyMembership(leaf, merkleProof);

    _;
  }
}