// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev struct used in memory to represent a cross margin account's option set
 *      this is a grouping of like underlying, collateral, strike (asset), and expiry
 *      used to calculate margin requirements
 * @param putWeights            amount of put options held in account (shorts and longs)
 * @param putStrikes            strikes of put options held in account (shorts and longs)
 * @param callWeights           amount of call options held in account (shorts and longs)
 * @param callStrikes           strikes of call options held in account (shorts and longs)
 * @param underlyingId          pomace id for underlying asset
 * @param underlyingDecimals    decimal points of underlying asset
 * @param numeraireId           pomace id for numeraire (aka strike) asset
 * @param numeraireDecimals     decimal points of numeraire (aka strike) asset
 * @param expiry                expiry of the option
 */
struct CrossMarginDetail {
    int256[] putWeights;
    uint256[] putStrikes;
    int256[] callWeights;
    uint256[] callStrikes;
    uint8 underlyingId;
    uint8 underlyingDecimals;
    uint8 numeraireId;
    uint8 numeraireDecimals;
    uint256 expiry;
}

/**
 * @dev an uncompressed Position struct, expanding tokenId to uint256
 * @param tokenId pomace option token id
 * @param amount number option tokens
 */
struct Position {
    uint256 tokenId;
    uint64 amount;
}

struct SettlementTracker {
    uint64 issued;
    uint80 totalDebt;
    uint80 totalPaid;
}