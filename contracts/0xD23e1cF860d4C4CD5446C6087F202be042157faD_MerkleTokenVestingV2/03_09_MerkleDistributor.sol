// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

abstract contract MerkleDistributor {
  bytes32 public merkleRoot;

  // This is a packed array of booleans.
  mapping(uint256 => uint256) private claimedBitMap;

  function __MerkleDistributor_init(bytes32 _merkleRoot) internal {
    merkleRoot = _merkleRoot;
  }

  /**
   * @dev Used to check if a merkle claim has been claimed from the merkle tree.
   * @param index The index of the award
   */
  function isClaimed(uint256 index) public view returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  /**
   * @dev Used to set that a merkle claim has been claimed.
   * @param index The index of the award
   */
  function _setClaimed(uint256 index) internal {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[claimedWordIndex] =
      claimedBitMap[claimedWordIndex] |
      (1 << claimedBitIndex);
  }

  function _verifyClaim(bytes32[] calldata merkleProof, bytes32 node)
    internal
    view
  {
    require(
      MerkleProofUpgradeable.verify(merkleProof, merkleRoot, node),
      "MerkleDistributor: Invalid proof"
    );
  }
}