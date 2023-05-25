// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ICases.sol";

/// @title Auction House state that can change
/// @notice These methods compose the auctions state, and will change per action.
interface IAuctionHouseVariables is ICases {
  /**
   * @notice The number of auctions since inception.
   */
  function round() external view returns (uint64);

  /**
   * @notice Returns data about a specific auction.
   * @param roundNumber The round number for the auction array to fetch
   * @return stabilisationCase The Auction struct including case
   */
  function auctions(uint64 roundNumber)
    external
    view
    returns (
      Cases stabilisationCase,
      uint256 targetFloatInEth,
      uint256 marketFloatInEth,
      uint256 bankInEth,
      uint256 startWethPrice,
      uint256 startBankPrice,
      uint256 endWethPrice,
      uint256 endBankPrice,
      uint256 basketFactor,
      uint256 delta,
      uint256 allowance
    );
}