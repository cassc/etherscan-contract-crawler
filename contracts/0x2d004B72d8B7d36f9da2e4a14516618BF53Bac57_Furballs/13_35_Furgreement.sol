// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./Furballs.sol";
import "./utils/FurProxy.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

/// @title Furballs
/// @author LFG Gaming LLC
/// @notice Has permissions to act as a proxy to the Furballs contract
/// @dev https://soliditydeveloper.com/ecrecover
contract Furgreement is EIP712, FurProxy {
  mapping(address => uint256) private nonces;

  address[] public addressQueue;

  mapping(address => PlayMove) public pendingMoves;

  // A "move to be made" in the sig queue
  struct PlayMove {
    uint32 zone;
    uint256[] tokenIds;
  }

  constructor(address furballsAddress) EIP712("Furgreement", "1") FurProxy(furballsAddress) { }

  /// @notice Proxy playMany to Furballs contract
  function playFromSignature(
    bytes memory signature,
    address owner,
    PlayMove memory move,
    uint256 deadline
  ) external {
    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
      keccak256("playMany(address owner,PlayMove memory move,uint256 nonce,uint256 deadline)"),
      owner,
      move,
      nonces[owner],
      deadline
    )));

    address signer = ECDSA.recover(digest, signature);
    require(signer == owner, "playMany: invalid signature");
    require(signer != address(0), "ECDSA: invalid signature");

    require(block.timestamp < deadline, "playMany: signed transaction expired");
    nonces[owner]++;

    if (pendingMoves[owner].tokenIds.length == 0) {
      addressQueue.push(owner);
    }
    pendingMoves[owner] = move;
  }
}