// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

struct CollectionConfig {
    bytes16 uuid;
    string name;
    string token;
    string slug;
    bytes16[] dependencies;
}

enum SaleType {
    FixedPrice,
    TieredDutchAuction,
    ContinuousDutchAuction
}

struct SaleConfig {
    SaleType saleType;
    uint32 maxSalePieces; // Maximum number of pieces to sell (including reserves)
    uint32 numReserved; // Number of pieces to reserve for specific wallets
    uint16 numRetained; // Number of pieces to retain for the artist
    uint40 startTime; // Sale start time
    uint40 auctionEndTime; // Sale doesn't stop here, but price decay stops. Needed for rebate if non-sellout.
    uint16 decayPeriodSeconds; // Period at which price decays
    uint24 decayRateBasisPoints; // Rate at which price decays
    bool hasRebate; // Whether or not to give a rebate to resting price
    uint256 initialPrice; // Starting price for Dutch Auction
    uint256 finalPrice; // Ending price for Dutch Auction
}

struct RoyaltyConfig {
    uint16 albaPrimaryFeeBasisPoints; // Share of primary sales to Alba (basis points)
    uint16 albaSecondaryFeeBasisPoints; // Share of secondary sales to Alba (basis points)
    uint16 royaltyBasisPoints; // Total % of royalties for sales
    bool enforceRoyalties; // Should use OperatorFilterer to enforce royalties?
}

struct StoredScript {
    string fileName;
    uint256 wrappedLength;
}