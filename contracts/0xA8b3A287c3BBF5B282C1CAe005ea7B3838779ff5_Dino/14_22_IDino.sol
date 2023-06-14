// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDino {
  error InvalidEtherValue();
  error MaxPerWalletOverflow();
  error TotalSupplyOverflow();
  error InvalidProof();
  error InvalidBurnPhase();

  struct MintRules {
    uint64 totalSupply;
    uint64 maxPerWallet;
    uint64 whitelistMaxPerWallet;
    uint64 freePerWallet;
    uint64 whitelistFreePerWallet;
    uint256 price;
    uint256 whitelistPrice;
  }

  enum Rarity {
    COMMON,
    UNCOMMON,
    RARE,
    MYTHICAL,
    EPIC,
    LEGENDARY
  }
}