// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IAuction.sol";

/// @title Auction House state that can change
/// @notice These methods are derived from the IAuctionHouseState.
interface IAuctionHouseDerivedState is IAuction {
  /**
   * @notice The price (that the Protocol with expect on expansion, and give on Contraction) for 1 FLOAT
   * @dev Under cases, this value is used differently:
   * - Contraction, Protocol buys FLOAT for pair.
   * - Expansion, Protocol sells FLOAT for pair.
   * @return wethPrice [e27] Expected price in wETH.
   * @return bankPrice [e27] Expected price in BANK.
   */
  function price() external view returns (uint256 wethPrice, uint256 bankPrice);

  /**
   * @notice The current step through the auction.
   * @dev block numbers since auction start (0 indexed)
   */
  function step() external view returns (uint256);

  /**
   * @notice Latest Auction alias
   */
  function latestAuction() external view returns (Auction memory);
}