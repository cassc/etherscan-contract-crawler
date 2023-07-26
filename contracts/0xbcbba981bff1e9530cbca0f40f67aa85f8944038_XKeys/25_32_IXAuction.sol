// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.20;

import "./AuctionEnums.sol";

interface IXAuction {
    /**
     * EVENTS
     */
    event Bid(
        uint8 indexed auctionId,
        address indexed bidder,
        uint256 bidAmount,
        uint256 bidderTotal
    );

    // when a bidder is refunded
    event RefundSent(address indexed recipient, uint256 value);

    event AuctionCreated(
        uint8 indexed auctionId,
        uint16 supply,
        uint8 maxWinPerWallet,
        uint64 minimumBid
    );

    event AuctionStarted(uint8 indexed auctionId);
    event MinimumBidChanged(uint8 indexed auctionId, uint256 newMinBid);
    event AuctionEnded(uint8 indexed auctionId);
    event PriceSet(uint8 indexed auctionId, uint256 newPrice);
    event ClaimsAndRefundsStarted(uint8 indexed auctionId);

    // when a user claims their NFTs and/or refunds
    event Claimed(address recipient, uint256 totalBid, uint256 podsWon, uint256 refund);

    /**
     * ERRORS
     */
    error InvalidCreateAuctionParams();
    error NullAddressParameter();
    error AuctionMustNotBeStarted();
    error InvalidStageForOperation(AuctionStage currentStage, AuctionStage requiredStage);
    error AuctionMustBeActive();
    error BidLowerThanMinimum(uint256 bid, uint256 minBid);
    error StageMustBeBiddingClosed(AuctionStage currentStage);
    error PriceMustBeSet();
    error PriceIsLowerThanTheMinBid(uint256 priceInput, uint256 minBid);
    error MultipleAuctionsViolation();
    error ZeroBids(address user);
    error NoActiveAuction();
    error AuctionDoesNotExist(uint8 auctionId);
    error MaxSupplyExceeded();

    error RefundFailed(address recipient, uint256 amount);
    error ContractCallersNotAllowed();

    // function bid() external payable;
}