// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct EditionConfig {
  string name;
  string symbol;
  uint256 maxTokens;
  uint256 tokenPrice;
  uint256 maxTokenPurchase;
  uint256 royaltyBPS;
}