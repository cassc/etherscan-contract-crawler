//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBucketAuction {
    error AlreadySentTokensToUser();
    error BucketAuctionActive();
    error BucketAuctionNotActive();
    error CannotSendMoreThanUserPurchased();
    error CannotSetPriceIfClaimable();
    error CannotSetPriceIfFirstTokenSent();
    error LowerThanMinBidAmount();
    error NotClaimable();
    error PriceHasBeenSet();
    error PriceNotSet();
    error TransferFailed();
    error UserAlreadyClaimed();

    struct User {
        uint216 contribution; // cumulative sum of ETH bids
        uint32 tokensClaimed; // tracker for claimed tokens
        bool refundClaimed; // has user been refunded yet
    }

    event Bid(
        address indexed bidder,
        uint256 bidAmount,
        uint256 bidderTotal,
        uint256 bucketTotal
    );
    event SetMinimumContribution(uint256 minimumContributionInWei);
    event SetPrice(uint256 price);
    event SetClaimable(bool claimable);
}