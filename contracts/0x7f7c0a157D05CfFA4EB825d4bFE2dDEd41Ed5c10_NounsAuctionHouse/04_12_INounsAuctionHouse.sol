// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Noun Auction Houses

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

interface INounsAuctionHouse {
    struct Auction {
        // ID for the Noun (ERC721 token ID)
        uint256 nounId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    event NewNounTokenInitialized(
        address nounsTokenContract,
        uint256 collectionId,
        uint256 reservePrice,
        uint256 duration,
        address creatorAddress,
        uint256 collectionSize,
        bytes32 merkleRoot
    );

    event AuctionCreated(uint256 collectionId, uint256 indexed nounId, uint256 startTime, uint256 endTime);

    event AuctionBid(uint256 collectionId, uint256 indexed nounId, address sender, uint256 value, bool extended);

    event AuctionExtended(uint256 collectionId, uint256 indexed nounId, uint256 endTime);

    event AuctionSettled(uint256 collectionId, uint256 indexed nounId, address winner, uint256 amount);

    event AuctionTimeBufferUpdated(uint256 timeBuffer);

    event AuctionReservePriceUpdated(uint256 collectionId, uint256 reservePrice);

    event AuctionMinBidIncrementPercentageUpdated(uint256 minBidIncrementPercentage);

    function settleAuction(uint256 collectionId) external;

    function settleCurrentAndCreateNewAuction(uint256 collectionId, string memory tokenCID, bytes32[] calldata merkleProof) external;

    function createBid(uint256 collectionId, uint256 nounId) external payable;

    function pause(uint256 collectionId) external;

    function unpause(uint256 collectionId, string memory tokenCID, bytes32[] calldata merkleProof) external;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 collectionId, uint256 reservePrice) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage) external;
}