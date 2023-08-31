//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermAuctionOfferLockerEvents is an interface that defines all events emitted by the Term Auction Offer Locker.
interface ITermAuctionOfferLockerEvents {
    event TermAuctionOfferLockerInitialized(
        bytes32 termRepoId,
        bytes32 termAuctionId,
        address termAuctionOfferLocker,
        uint256 auctionStartTime,
        uint256 revealTime,
        uint256 maxOfferPrice,
        uint256 minimumTenderAmount
    );

    event OfferLocked(
        bytes32 termAuctionId,
        bytes32 id,
        address offeror,
        bytes32 offerPrice,
        uint256 amount,
        address token,
        address referralAddress
    );

    event OfferRevealed(bytes32 termAuctionId, bytes32 id, uint256 offerPrice);

    event OfferUnlocked(bytes32 termAuctionId, bytes32 id);

    event OfferLockingPaused(bytes32 termAuctionId, bytes32 termRepoId);

    event OfferLockingUnpaused(bytes32 termAuctionId, bytes32 termRepoId);

    event OfferUnlockingPaused(bytes32 termAuctionId, bytes32 termRepoId);

    event OfferUnlockingUnpaused(bytes32 termAuctionId, bytes32 termRepoId);
}