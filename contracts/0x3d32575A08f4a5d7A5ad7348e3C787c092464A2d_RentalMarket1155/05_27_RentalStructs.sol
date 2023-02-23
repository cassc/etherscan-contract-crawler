// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import {NFT, Fee, Metadata} from "./BaseStructs.sol";

struct RentalPrice {
    address paymentToken;
    uint256 pricePerCycle;
    uint256 cycle;
}

struct LendOrder {
    address maker;
    address taker; //private order
    NFT nft;
    RentalPrice price;
    uint256 minCycleAmount;
    uint256 maxRentExpiry;
    uint256 nonce;
    uint256 salt;
    uint64 durationId;
    Fee[] fees;
    Metadata metadata;
}

struct RentOffer {
    address maker;
    address taker; //private order
    NFT nft;
    RentalPrice price;
    uint256 cycleAmount;
    uint256 offerExpiry;
    uint256 nonce;
    uint256 salt;
    Fee[] fees;
    Metadata metadata;
}