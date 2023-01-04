// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Enum indicating whether a token is a "fan" or "brand" token. Fan
/// tokens are intended for purchase by project patrons and have a lower protocol
/// fee and royalties than brand tokens.
enum TierType {
    Fan,
    Brand
}

/// @param tierType Whether this tier is a "fan" or "brand" token.
/// @param supply Maximum token supply in this tier.
/// @param price Price per token.
/// @param limitPerAddress Maximum number of tokens that may be minted by address.
/// @param allowListRoot Merkle root of an allowlist for the presale phase.
struct TierParams {
    TierType tierType;
    uint256 supply;
    uint256 price;
    uint256 limitPerAddress;
    bytes32 allowListRoot;
}

/// @param tierType Whether this tier is a "fan" or "brand" token.
/// @param supply Maximum token supply in this tier.
/// @param price Price per token.
/// @param limitPerAddress Maximum number of tokens that may be minted by address.
/// @param allowListRoot Merkle root of an allowlist for the presale phase.
/// @param minted Total number of tokens minted in this tier.
struct Tier {
    TierType tierType;
    uint256 supply;
    uint256 price;
    uint256 limitPerAddress;
    bytes32 allowListRoot;
    uint256 minted;
}