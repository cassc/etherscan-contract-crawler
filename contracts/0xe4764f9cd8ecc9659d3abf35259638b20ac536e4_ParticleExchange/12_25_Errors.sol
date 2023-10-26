// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Errors {
    error Unauthorized();
    error UnregisteredMarketplace();
    error InvalidParameters();
    error InvalidLien();
    error LoanStarted();
    error InactiveLoan();
    error LiquidationHasNotReached();
    error MartketplaceFailedToTrade();
    error InvalidNFTSell();
    error InvalidNFTBuy();
    error NFTNotReceived();
    error Overspend();
    error UnmatchedCollections();
    error BidTaken();
    error BidNotTaken();
    error AuctionStarted();
    error AuctionNotStarted();
    error AuctionEndTooSoon();
}