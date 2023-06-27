// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct EditionConfig {
  string name;
  string symbol;
  bool hasAdjustableCap;
  bool isSoulbound;
  uint32 maxTokens;
  uint32 maxTokenPurchase;
  uint32 presaleStart;
  uint32 presaleEnd;
  uint32 saleStart;
  uint32 saleEnd;
  uint16 royaltyBPS;
  uint96 tokenPrice;
  address feeManager;
  address payoutAddress;
  bytes32 presaleMerkleRoot;
}