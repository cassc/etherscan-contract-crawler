// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title Interface that allows a user to draw an address using a random number
interface ITicket {
  /// @notice Selects a user using a random number. The random number will be uniformly bounded to the ticket totalSupply.
  /// @param randomNumber The random number to use to select a user.
  /// @return The winner
  function draw(uint256 randomNumber) external view returns (address);
}