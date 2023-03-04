// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

/**
 * @title Interface for routing calls to the NFT Market to set buy now prices.
 * @author HardlyDifficult
 */
interface INFTMarketBuyNow {
  function setBuyPrice(address nftContract, uint256 tokenId, uint256 price) external;
}