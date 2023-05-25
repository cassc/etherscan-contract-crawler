// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

/// @title Auction House actions that require certain level of privilege
/// @notice Contains Auction House methods that may only be called by controller
interface IAuctionHouseGovernedActions {
  /**
   * @notice Modify a uint256 parameter
   * @param parameter The parameter name to modify
   * @param data New value for the parameter
   */
  function modifyParameters(bytes32 parameter, uint256 data) external;

  /**
   * @notice Modify an address parameter
   * @param parameter The parameter name to modify
   * @param data New address for the parameter
   */
  function modifyParameters(bytes32 parameter, address data) external;
}