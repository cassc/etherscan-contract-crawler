// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/// @title Auction House state that can change by governance.
/// @notice These methods provide vision on specific state that could be used in wrapper contracts.
interface IAuctionHouseState {
  /**
   * @notice The buffer around the starting price to handle mispriced / stale oracles.
   * @dev Basis point
   * Starts at 10% / 1e3 so market price is buffered by 110% or 90%
   */
  function buffer() external view returns (uint16);

  /**
   * @notice The fee taken by the protocol.
   * @dev Basis point
   */
  function protocolFee() external view returns (uint16);

  /**
   * @notice The cap based on total FLOAT supply to change in a single auction. E.g. 10% cap => absolute max of 10% of total supply can be minted / burned
   * @dev Basis point
   */
  function allowanceCap() external view returns (uint32);
}