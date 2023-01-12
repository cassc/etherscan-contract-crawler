// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

/** 
 * Each class of Runo NFT has its own tier level
 * [AIN Wokrer NFT tier level]
 * tier 0: cpu
 * tier 1: gpu
 * tier 2: highGpu
 */
struct TierInfo {
  uint256 totalSupply;
  uint256 currentSupply;
  uint256 minTokenId;
}

struct ClassInfo {
  uint256 maxTier;
}

struct SalesInfo {
  TierInfo[] tokenTierInfo;
  uint256[] priceInfo;
}