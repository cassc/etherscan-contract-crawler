//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @dev TermAuctionOffer represents an offer to lend an specific amount of tokens at a specific interest rate (or better)
struct CompleteAuctionInput {
    bytes32[] revealedBidSubmissions;
    bytes32[] expiredRolloverBids;
    bytes32[] unrevealedBidSubmissions;
    bytes32[] revealedOfferSubmissions;
    bytes32[] unrevealedOfferSubmissions;
}