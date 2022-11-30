// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

/// @title Events emitted by a pre-IDO events
/// @notice Contains all events emitted by the pre-IDO contract
interface IPreIDOEvents {
  /// @notice Emitted when tokens is locked in the pre-IDO contract
  /// @param sender The sender address whose the locked tokens belong
  /// @param id The order ID used to tracking order information
  /// @param amount The amount of tokens to be locked
  /// @param lockOnBlock The block timestamp when tokens locked inside the pre-IDO
  /// @param releaseOnBlock The block timestamp when tokens can be redeem or claimed from the time-locked contract
  event LockTokens(address indexed sender, uint256 indexed id, uint256 amount, uint256 lockOnBlock, uint256 releaseOnBlock);   

  /// @notice Emitted when tokens is unlocked or claimed by `receiver` from the time-locked contract
  /// @param receiver The receiver address where the tokens to be distributed to
  /// @param id The order ID used to tracking order information
  /// @param amount The amount of tokens has been distributed
  event UnlockTokens(address indexed receiver, uint256 indexed id, uint256 amount);
}