//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermAuctionLockerErrors is an interface that defines all errors emitted by the Term Auction Bid and Offer Lockers.
interface ITermAuctionLockerErrors {
    error AlreadyTermContractPaired();
    error AuctionNotOpen();
    error AuctionNotRevealing();
    error AuctionNotClosed();

    error AuctionStartsAfterReveal(uint256 start, uint256 reveal);
    error AuctionRevealsAfterEnd(uint256 reveal, uint256 end);

    error PurchaseTokenNotApproved(address token);
    error CollateralTokenNotApproved(address token);

    error TenderPriceTooHigh(bytes32 id, uint256 maxPrice);

    error LockingPaused();
    error UnlockingPaused();

    error InvalidSelfReferral();
}