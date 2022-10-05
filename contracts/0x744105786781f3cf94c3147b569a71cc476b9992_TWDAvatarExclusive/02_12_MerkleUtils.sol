// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./MerkleProof.sol";

library MerkleUtils {
  function verifyWithQuantity(
    bytes32 merkleRoot,
    bytes32[] calldata merkleProof,
    address sender,
    uint256 maxAmount
  ) internal pure returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(sender, maxAmount));
    return MerkleProof.verify(merkleProof, merkleRoot, leaf);
  }
}