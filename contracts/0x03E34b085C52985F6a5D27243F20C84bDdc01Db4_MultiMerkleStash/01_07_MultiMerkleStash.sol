// SPDX-License-Identifier: MIT
// Merkle Stash

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract MultiMerkleStash is Ownable {
  using SafeERC20 for IERC20;

  struct claimParam {
      address token;
      uint256 index;
      uint256 amount;
      bytes32[] merkleProof;
  }

  // environment variables for updateable merkle
  mapping(address => bytes32) public merkleRoot;
  mapping(address => uint256) public update;

  // This is a packed array of booleans.
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private claimedBitMap;

  function isClaimed(address token, uint256 index) public view returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[token][update[token]][claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function _setClaimed(address token, uint256 index) private {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[token][update[token]][claimedWordIndex] = claimedBitMap[token][update[token]][claimedWordIndex] | (1 << claimedBitIndex);
  }

  function claim(address token, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) public {
    require(merkleRoot[token] != 0, 'frozen');
    require(!isClaimed(token, index), 'Drop already claimed.');

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    require(MerkleProof.verify(merkleProof, merkleRoot[token], node), 'Invalid proof.');

    _setClaimed(token, index);
    IERC20(token).safeTransfer(account, amount);

    emit Claimed(token, index, amount, account, update[token]);
  }

  function claimMulti(address account, claimParam[] calldata claims) external {
    for(uint256 i=0;i<claims.length;++i) {
      claim(claims[i].token, claims[i].index, account, claims[i].amount, claims[i].merkleProof);
    }
  }

  // MULTI SIG FUNCTIONS //

  function updateMerkleRoot(address token, bytes32 _merkleRoot) public onlyOwner {

    // Increment the update (simulates the clearing of the claimedBitMap)
    update[token] += 1;
    // Set the new merkle root
    merkleRoot[token] = _merkleRoot;

    emit MerkleRootUpdated(token, _merkleRoot, update[token]);
  }

  // EVENTS //
  event Claimed(address indexed token, uint256 index, uint256 amount, address indexed account, uint256 indexed update);
  event MerkleRootUpdated(address indexed token, bytes32 indexed merkleRoot, uint256 indexed update);
}