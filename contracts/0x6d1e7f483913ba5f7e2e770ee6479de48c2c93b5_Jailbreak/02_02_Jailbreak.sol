// SPDX_License_Identifier: UNLICENSED

pragma solidity 0.8.17;

import "openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error TransferFailed();
error MustOwnCorn();
error MustOwnQ00tant();
error OnCooldown();

interface Q00ts {
  function transferFrom(address, address, uint256) external;
  function balanceOf(address) external view returns (uint256);
  function mint(address recipient, uint256 amount) external payable;
}

contract Jailbreak {
  uint256 public threshold;

  mapping(address => uint256) lastFailedAttempt;

  struct EpochDetails {
    uint32 q00tantPoints;
    uint32 q00nicornPoints;
    bytes32 q00tantRoot;
    bytes32 q00nicornRoot;
  }

  EpochDetails public epochDetails;
  Q00ts q00nicorns = Q00ts(0xb1b853a1aaC513f2aB91133Ca8AE5d78c24cB828);
  Q00ts q00tants = Q00ts(0x862c9B564fbDD34983Ed3655aA9F68E0ED86C620);

  address private CAMP_Q00NTA = 0xd8Cc0336bcdED86Ea7b08144aAc517348bF27430;
  address private BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

  constructor() {
    epochDetails.q00tantRoot = 0xc60e3580c6ee0d12dcfeafd5399a2efbee5a5195845691b5ce74c6b906fbc357;
    epochDetails.q00nicornRoot = 0x975d6ef8b3b6305c6cb4f776681318a0f1296fe3b67bebd58af349118a01f2ab;
  }

  function attemptSaveQ00nicorn(uint256 tokenId, bytes32[] calldata proof) external {
    if (!canAttack(msg.sender)) revert OnCooldown();

    bytes32 leaf = keccak256((abi.encodePacked(msg.sender)));

    if (!MerkleProof.verifyCalldata(proof, epochDetails.q00nicornRoot, leaf)) {
      revert MustOwnCorn();
    }

    if (random() < threshold) {
      q00nicorns.transferFrom(CAMP_Q00NTA, msg.sender, tokenId);

      ++epochDetails.q00nicornPoints;
    } else {
      lastFailedAttempt[msg.sender] = block.timestamp;
    }
  }

  function attemptBurnQ00nicorn(uint256 tokenId, bytes32[] calldata proof) external {
    if (!canAttack(msg.sender)) revert OnCooldown();

    bytes32 leaf = keccak256((abi.encodePacked(msg.sender)));

    if (!MerkleProof.verifyCalldata(proof, epochDetails.q00tantRoot, leaf)) {
      revert MustOwnQ00tant();
    }

    if (random() > threshold) {
      q00nicorns.transferFrom(CAMP_Q00NTA, BURN_ADDRESS, tokenId);
      q00tants.mint(msg.sender, 1);

      ++epochDetails.q00tantPoints;
    } else {
      lastFailedAttempt[msg.sender] = block.timestamp;
    }
  }

  function canAttack(address user) public view returns (bool) {
    return block.timestamp - lastFailedAttempt[user] > 24 hours;
  }

  function setThreshold(uint256 _threshold) external {
    if (msg.sender != 0xd8Cc0336bcdED86Ea7b08144aAc517348bF27430) revert();
    threshold = _threshold;
  }

  function random() private view returns (uint8) {
    return uint8(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty)))%251);
  }
}