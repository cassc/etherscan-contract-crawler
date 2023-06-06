// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Ballot {
  using ECDSA for bytes32;

  enum VoteType {
    For,
    Against
  }

  // keccak256("Ballot(bytes32 proposalHash,uint8 support)");
  bytes32 public constant BALLOT_TYPEHASH = 0xd900570327c4c0df8dd6bdd522b7da7e39145dd049d2fd4602276adcd511e3c2;

  function hash(bytes32 _proposalHash, VoteType _support) internal pure returns (bytes32) {
    return keccak256(abi.encode(BALLOT_TYPEHASH, _proposalHash, _support));
  }
}