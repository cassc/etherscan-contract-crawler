//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

import "./ITermAuctionLockerErrors.sol";

/// @notice ITermAuctionBidLockerErrors is an interface that defines all errors emitted by the Term Auction Bid Locker.
interface ITermAuctionBidLockerErrors is ITermAuctionLockerErrors {
    error BidAmountTooLow(uint256 amount);
    error BidAlreadyRevealed();
    error BidCountIncorrect(uint256 bidCount);
    error BidNotOwned();
    error BidNotRevealed(bytes32 bidId);
    error BidPriceModified(bytes32 id);
    error BidRevealed(bytes32 bidId);
    error CollateralAmountTooLow();
    error GeneratingExistingBid(bytes32 bidId);
    error InvalidTermRepoServicer();
    error RevealedBidsNotSorted();
    error RolloverBid();

    error MaxBidCountReached();
    error NoCollateralToUnlock();
    error NonExistentBid(bytes32 bidId);
    error NonExpiredRolloverBid(bytes32 bidId);
    error NonRolloverBid(bytes32 id);

    error RolloverBidExpired(bytes32 bidId);
}