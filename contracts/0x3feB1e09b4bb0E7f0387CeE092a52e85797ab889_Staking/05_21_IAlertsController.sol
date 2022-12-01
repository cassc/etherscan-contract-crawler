// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IAlertsController {
  /// @param alerter The address of an alerter
  /// @param roundId The feed's round ID that an alert has been raised for
  /// @param rewardAmount The amount of LINK rewarded to the alerter
  /// @notice Emitted when a valid alert is raised for a feed round
  event AlertRaised(address alerter, uint256 roundId, uint256 rewardAmount);

  /// @param roundId The feed's round ID that the alerter is trying to raise an alert for
  /// @notice This error is thrown when an alerter tries to raise an
  // alert for a round that has already been alerted.
  error AlertAlreadyExists(uint256 roundId);

  /// @notice This error is thrown when alerting conditions are not met and the
  /// alert is invalid.
  error AlertInvalid();

  /// @notice This function creates an alert for a stalled feed
  function raiseAlert() external;

  /// @notice This function checks to see whether the alerter may raise an alert
  /// to claim rewards
  function canAlert(address alerter) external view returns (bool);
}