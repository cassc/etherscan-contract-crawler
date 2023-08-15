// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IJBPriceFeed} from './IJBPriceFeed.sol';

interface IJBPrices {
  event AddFeed(uint256 indexed currency, uint256 indexed base, IJBPriceFeed feed);

  function feedFor(uint256 currency, uint256 base) external view returns (IJBPriceFeed);

  function priceFor(
    uint256 currency,
    uint256 base,
    uint256 decimals
  ) external view returns (uint256);

  function addFeedFor(uint256 currency, uint256 base, IJBPriceFeed priceFeed) external;
}