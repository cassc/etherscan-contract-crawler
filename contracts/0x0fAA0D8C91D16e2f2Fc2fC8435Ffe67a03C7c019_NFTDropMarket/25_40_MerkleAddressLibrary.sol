// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title Helper library for interacting with Merkle trees & proofs.
 * @author batu-inal & HardlyDifficult & reggieag
 */
library MerkleAddressLibrary {
  using MerkleProof for bytes32[];

  /**
   * @notice Gets the root for a merkle tree comprised only of addresses.
   */
  function getMerkleRootForAddress(address user, bytes32[] calldata proof) internal pure returns (bytes32 root) {
    bytes32 leaf = keccak256(abi.encodePacked(user));
    root = proof.processProofCalldata(leaf);
  }
}