// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

enum PriceStrategy {
    SIMPLIFIED,
    TIERS
}

// Struct for pricing rules
struct PriceRule {
    uint256 id;
    string name;
    uint256 minMint; // How much min supply needed for rule to take effect - zero means no min
    address[] tokens;
    uint256[] prices;
}

struct BatchPriceRule {
    uint256 idFrom; // Which tokenId id starts the rule - inclusive
    uint256 idTo; // Which tokenId  ends the rule - inclusive
    uint256 minMint; // How much min supply needed for rule to take effect - zero means no min
    address[] tokens;
    uint256[] prices;
}

struct ERC1155Config {
    PriceStrategy strategy;
    address[] acceptedPaymentTokens;
    uint256[] paymentTokensPricing;
    uint256[] globalSupplyConfigs;
}