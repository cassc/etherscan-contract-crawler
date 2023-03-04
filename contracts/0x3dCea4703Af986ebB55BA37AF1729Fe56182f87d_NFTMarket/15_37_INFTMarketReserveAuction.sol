// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

/**
 * @title Interface for routing calls to the NFT Market to create reserve auctions.
 * @author HardlyDifficult
 */
interface INFTMarketReserveAuction {
  function createReserveAuctionV2(
    address nftContract,
    uint256 tokenId,
    uint256 reservePrice,
    uint256 exhibitionId
  ) external returns (uint256 auctionId);
}