// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct EditionConfig {
  string name;
  string symbol;
  bool hasAdjustableCap;
  uint256 maxTokens;
  uint256 tokenPrice;
  uint256 maxTokenPurchase;
  bytes32 presaleMerkleRoot;
  uint256 presaleStart;
  uint256 presaleEnd;
  uint256 saleStart;
  uint256 saleEnd;
  uint256 royaltyBPS;
}