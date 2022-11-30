// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable-next-line max-line-length
// Adapted from https://github.com/Uniswap/merkle-distributor/blob/c3255bfa2b684594ecd562cacd7664b0f18330bf/contracts/MerkleDistributor.sol.
pragma solidity 0.6.12;

import "@openzeppelin/contracts/cryptography/MerkleProof.sol";

import "../interfaces/ICommunityRewards.sol";
import "../interfaces/IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
  address public immutable override communityRewards;
  bytes32 public immutable override merkleRoot;

  // @dev This is a packed array of booleans.
  mapping(uint256 => uint256) private acceptedBitMap;

  constructor(address communityRewards_, bytes32 merkleRoot_) public {
    require(communityRewards_ != address(0), "Cannot use the null address");
    require(merkleRoot_ != 0, "Invalid merkle root provided");
    communityRewards = communityRewards_;
    merkleRoot = merkleRoot_;
  }

  function isGrantAccepted(uint256 index) public view override returns (bool) {
    uint256 acceptedWordIndex = index / 256;
    uint256 acceptedBitIndex = index % 256;
    uint256 acceptedWord = acceptedBitMap[acceptedWordIndex];
    uint256 mask = (1 << acceptedBitIndex);
    return acceptedWord & mask == mask;
  }

  function _setGrantAccepted(uint256 index) private {
    uint256 acceptedWordIndex = index / 256;
    uint256 acceptedBitIndex = index % 256;
    acceptedBitMap[acceptedWordIndex] = acceptedBitMap[acceptedWordIndex] | (1 << acceptedBitIndex);
  }

  function acceptGrant(
    uint256 index,
    uint256 amount,
    uint256 vestingLength,
    uint256 cliffLength,
    uint256 vestingInterval,
    bytes32[] calldata merkleProof
  ) external override {
    require(!isGrantAccepted(index), "Grant already accepted");

    // Verify the merkle proof.
    //
    /// @dev Per the Warning in
    /// https://github.com/ethereum/solidity/blob/v0.6.12/docs/abi-spec.rst#non-standard-packed-mode,
    /// it is important that no more than one of the arguments to `abi.encodePacked()` here be a
    /// dynamic type (see definition in
    /// https://github.com/ethereum/solidity/blob/v0.6.12/docs/abi-spec.rst#formal-specification-of-the-encoding).
    bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount, vestingLength, cliffLength, vestingInterval));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");

    // Mark it accepted and perform the granting.
    _setGrantAccepted(index);
    uint256 tokenId = ICommunityRewards(communityRewards).grant(
      msg.sender,
      amount,
      vestingLength,
      cliffLength,
      vestingInterval
    );

    emit GrantAccepted(tokenId, index, msg.sender, amount, vestingLength, cliffLength, vestingInterval);
  }
}