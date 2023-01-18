// SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.9;

struct NFTBaseAttributes {
  uint256 id;
  //INFO: Each position in this arrays represent an attribute
  string[] values;
}

struct NFTBaseAttributesRequest {
  NFTBaseAttributes[] nFTsBaseAttributes;
}

struct Stage {
  string name;
  uint256 price;
  uint32 maxAmount;
  bytes32 root;
  mapping(address => uint32) minters;
  function(uint32, uint32, bytes32[] calldata, bytes calldata) internal beforeMint;
}