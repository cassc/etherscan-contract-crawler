// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title MerkleDistributor
/// @author Bluejay Core Team
/// @notice MerkleDistributor is a base contract for contracts using merkle tree to distribute assets.
/// @dev Code inspired by https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol
/// Merkle root generation script inspired by https://github.com/Uniswap/merkle-distributor/tree/master/scripts
abstract contract MerkleDistributor {
  /// @notice Merkle root of the entire distribution
  /// @dev Setting the merkle root after distribution has begun may result in unintended consequences
  bytes32 public merkleRoot;

  /// @notice Packed array of booleans
  mapping(uint256 => uint256) private claimedBitMap;

  event Distributed(uint256 index, address account, uint256 amount);

  /// @notice Checks `claimedBitMap` to see if the distribution to a given index has been claimed
  /// @param index Index of the distribution to check
  /// @return claimed True if the distribution has been claimed, false otherwise
  function isClaimed(uint256 index) public view returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  /// @notice Internal function to set a distribution as claimed
  /// @param index Index of the distribution to mark as claimed
  function _setClaimed(uint256 index) private {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[claimedWordIndex] =
      claimedBitMap[claimedWordIndex] |
      (1 << claimedBitIndex);
  }

  /// @notice Internal function to claim a distribution
  /// @param index Index of the distribution to claim
  /// @param account Address of the account to claim the distribution
  /// @param amount Amount of the distribution to claim
  /// @param merkleProof Array of bytes32s representing the merkle proof of the distribution
  function _claim(
    uint256 index,
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) internal {
    require(!isClaimed(index), "Already claimed");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");

    // Mark it claimed
    _setClaimed(index);

    emit Distributed(index, account, amount);
  }

  /// @notice Internal function to set the merkle root
  /// @dev Setting the merkle root after distribution has begun may result in unintended consequences
  function _setMerkleRoot(bytes32 _merkleRoot) internal {
    merkleRoot = _merkleRoot;
  }
}