// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/**
 * @title Basket Actions with suitable access control
 * @notice Contains actions which can only be called by governance.
 */
interface IBasketGovernedActions {
  event NewTargetRatio(uint256 targetRatio);

  /**
   * @notice Sets the basket target factor, initially "1"
   * @dev Expects an [e27] fixed point decimal value.
   * Target Ratio is what the basket factor is "aiming for",
   * i.e. target ratio = 0.8 then an 80% support from the basket
   * results in a 100% Basket Factor.
   * @param _targetRatio [e27] The new Target ratio
   */
  function setTargetRatio(uint256 _targetRatio) external;

  /**
   * @notice Connect and approve a new auction house to spend from the basket.
   * @dev Note that any allowance can be set, and even type(uint256).max will
   * slowly be eroded.
   * @param _auctionHouse The Auction House address to approve
   * @param _allowance The amount of the underlying token it can spend
   */
  function buildAuctionHouse(address _auctionHouse, uint256 _allowance)
    external;

  /**
   * @notice Remove an auction house, allows easy upgrades.
   * @param _auctionHouse The Auction House address to revoke.
   */
  function burnAuctionHouse(address _auctionHouse) external;
}