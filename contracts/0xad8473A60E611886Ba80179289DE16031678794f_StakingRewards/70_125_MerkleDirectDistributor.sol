// SPDX-License-Identifier: GPL-3.0-only
// solhint-disable-next-line max-line-length
// Adapted from https://github.com/Uniswap/merkle-distributor/blob/c3255bfa2b684594ecd562cacd7664b0f18330bf/contracts/MerkleDistributor.sol.
pragma solidity 0.6.12;

import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IERC20withDec.sol";
import "../interfaces/IMerkleDirectDistributor.sol";
import "../protocol/core/BaseUpgradeablePausable.sol";

contract MerkleDirectDistributor is IMerkleDirectDistributor, BaseUpgradeablePausable {
  using SafeERC20 for IERC20withDec;

  address public override gfi;
  bytes32 public override merkleRoot;

  // @dev This is a packed array of booleans.
  mapping(uint256 => uint256) private acceptedBitMap;

  function initialize(
    address owner,
    address _gfi,
    bytes32 _merkleRoot
  ) public initializer {
    require(owner != address(0), "Owner address cannot be empty");
    require(_gfi != address(0), "GFI address cannot be empty");
    require(_merkleRoot != 0, "Invalid Merkle root");

    __BaseUpgradeablePausable__init(owner);

    gfi = _gfi;
    merkleRoot = _merkleRoot;
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
    bytes32[] calldata merkleProof
  ) external override whenNotPaused {
    require(!isGrantAccepted(index), "Grant already accepted");

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, msg.sender, amount));
    require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");

    // Mark it accepted and perform the granting.
    _setGrantAccepted(index);
    IERC20withDec(gfi).safeTransfer(msg.sender, amount);

    emit GrantAccepted(index, msg.sender, amount);
  }
}