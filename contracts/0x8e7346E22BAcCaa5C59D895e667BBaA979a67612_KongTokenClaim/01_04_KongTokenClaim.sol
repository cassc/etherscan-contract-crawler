// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.9;

import "../contracts/ILand.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "hardhat/console.sol";

contract KongTokenClaim {

  ILand public immutable landERC20;
  bytes32 public immutable merkleRoot;

  uint256 claimStartTime;
  uint256 claimEndTime;

  mapping(address => bool) public hasClaimed;

  error AlreadyClaimed();
  error NotInMerkle();

  constructor(ILand _landERC20, bytes32 _merkleRoot, uint256 _claimStartTime, uint256 _claimEndTime) { 
      landERC20 = _landERC20;
      merkleRoot = _merkleRoot;
      claimStartTime = _claimStartTime;
      claimEndTime = _claimEndTime;
  }

  event Claim(address indexed to, uint256 amount);

  function claim(address to, uint256 amount, bytes32[] calldata proof) external {

    // Verify that timelock has expired.
    require(block.timestamp >= claimStartTime, 'Cannot claim yet.');   

    // Verify that timelock has expired.
    require(block.timestamp <= claimEndTime, 'Past claim date.'); 

    // Throw if address has already claimed tokens
    if (hasClaimed[to]) revert AlreadyClaimed();

    // Verify merkle proof, or revert if not in tree
    bytes32 leaf = keccak256(abi.encodePacked(to, amount));
    bool isValidLeaf = MerkleProof.verify(proof, merkleRoot, leaf);
    if (!isValidLeaf) revert NotInMerkle();

    // Set address to claimed
    hasClaimed[to] = true;

    // Mint tokens to address
    landERC20.mint(to, amount);

    // Emit claim event
    emit Claim(to, amount);
  }
}