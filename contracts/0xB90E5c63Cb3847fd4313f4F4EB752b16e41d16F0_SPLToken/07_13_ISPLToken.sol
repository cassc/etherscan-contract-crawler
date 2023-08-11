// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SPL Interface
 * @author Splendor Network
 * @notice This is the interface of the token of SPL
 */
interface ISPLToken {
  /*///////////////////////////////////////////////////////////////
                            EVENTS
  //////////////////////////////////////////////////////////////*/

  /// @dev Emitted when the user bougth Tokens
  event TokenBoughtWithWBTC(address buyer, uint256 amount);

  /// @dev Emitted when the user bougth Tokens
  event TokenBoughtWithCGLD(address buyer, uint256 amount, uint256 price);
}