// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

interface INFTMarketReserveAuction {
  function createReserveAuctionV2(address nftContract, uint256 tokenId, uint256 reservePrice, uint256 exhibitionId)
    external
    returns (uint256 auctionId);
}