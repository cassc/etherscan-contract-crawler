// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import { MerkleDistributor, MerkleProof, AlreadyClaimed, InvalidProof } from './MerkleDistributor.sol';
import { BaseToken } from './BaseToken.sol';

contract STOToken is BaseToken, MerkleDistributor {
  uint256 public constant MAX_SUPPLY = 300_000 ether;

  constructor(bytes32 merkleRoot_) BaseToken('Share Token', 'STO') MerkleDistributor(address(this), merkleRoot_) {}

  function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) public override {
    if (isClaimed(index)) revert AlreadyClaimed();

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    if (!MerkleProof.verify(merkleProof, merkleRoot, node)) revert InvalidProof();

    // Mark it claimed and send the token.
    _setClaimed(index);
    _mint(account, amount);

    emit Claimed(index, account, amount);
  }
}