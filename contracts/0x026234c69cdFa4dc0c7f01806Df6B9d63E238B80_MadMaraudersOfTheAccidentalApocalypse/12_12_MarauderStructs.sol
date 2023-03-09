// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

struct MintableTokenDetails {
  uint16 startTokenId;
  uint16 currentTokenId;
}

struct ClaimableTokenDetails {
  uint16 totalSupply;
  uint16 currentBonusTokenId;
  uint16 maxBonusTokenId;
}

struct PhaseDetails {
  bytes32 root;
  uint64 startTime;
}

struct ItemDetails {
  bytes4 mintFunctionSelector;
  uint16 numUnitsSold;
  uint16 maxUnitsAllowed;
  uint16 maxNerdPhaseUnitsAllowedPerWallet;
  address mintContractAddress;
  uint64 price;
  uint64 discountedPrice;
}

struct MintTracker {
  uint32 numBoxesMinted;
  uint32 numEnforcersMinted;
  uint32 numWarlordsMinted;
  uint32 numSerumsMinted;
}