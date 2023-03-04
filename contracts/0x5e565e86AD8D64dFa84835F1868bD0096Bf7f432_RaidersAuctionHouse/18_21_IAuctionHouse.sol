// SPDX-License-Identifier: GPL-3.0

/// @title Interface for Auction Houses

pragma solidity ^0.8.9;

interface IAuctionHouse {
  struct Auction {
    // Token address (ERC721 or ERC1155)
    address token;
    // Token ID
    uint256 tokenId;
    // Type of contract (ERC1155 when flag is false)
    bool isERC721;
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
    // Address to send ETH after final bid
    address payable treasury;
    // Block number of auction start
    uint256 startBlock;
    // Block number with the last bid
    uint256 lastBidBlock;
  }

  event AuctionCreated(
    uint256 indexed id,
    address token,
    uint256 tokenId,
    uint256 startTime,
    uint256 endTime
  );

  event AuctionBid(
    uint256 indexed id,
    address token,
    uint256 tokenId,
    address sender,
    uint256 value,
    bool extended
  );

  event AuctionExtended(
    uint256 indexed id,
    address token,
    uint256 tokenId,
    uint256 endTime
  );

  event AuctionSettled(
    uint256 indexed id,
    address token,
    uint256 tokenId,
    address winner,
    uint256 amount
  );

  event AuctionTimeBufferUpdated(uint256 timeBuffer);

  event AuctionReservePriceUpdated(uint256 reservePrice);

  event AuctionMinBidIncrementPercentageUpdated(
    uint256 minBidIncrementPercentage
  );

  function createAuction(
    address from,
    address token,
    uint256 tokenId,
    uint256 startTime,
    address payable treasury
  ) external;

  function getCurrentAuction() external returns (Auction memory);

  function cancelAuction() external;

  function settleAuction() external;

  function createBid() external payable;

  function setTimeBuffer(uint256 timeBuffer) external;

  function setReservePrice(uint256 reservePrice) external;

  function setMinBidIncrementPercentage(
    uint8 minBidIncrementPercentage
  ) external;
}