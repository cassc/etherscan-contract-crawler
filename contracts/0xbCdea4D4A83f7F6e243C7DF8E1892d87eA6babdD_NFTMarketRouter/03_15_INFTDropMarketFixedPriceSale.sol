// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.12;

/**
 * @title Interface for routing calls to the NFT Drop Market to create fixed price sales.
 * @author HardlyDifficult & reggieag
 */
interface INFTDropMarketFixedPriceSale {
  function createFixedPriceSaleV3(
    address nftContract,
    uint256 exhibitionId,
    uint256 price,
    uint256 limitPerAccount,
    uint256 generalAvailabilityStartTime,
    uint256 txDeadlineTime
  ) external;
}