// SPDX-License-Identifier: MIT

// copied from @rarible/royalties/contracts/LibPart.sol
// to support the newest solidity version
pragma solidity ^0.8.9;

library LibPart {
  bytes32 public constant TYPE_HASH =
    keccak256('Part(address account,uint96 value)');

  struct Part {
    address payable account;
    uint96 value;
  }

  function hash(Part memory part) internal pure returns (bytes32) {
    return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
  }
}