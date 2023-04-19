// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IRoyaltyGuard} from "../IRoyaltyGuard.sol";

/// @title IRoyaltyGuard
/// @author highland, koloz, van arman
/// @notice Interface for a deadman trigger extension to IRoyaltyGuard
interface IRoyaltyGuardDeadmanTrigger is IRoyaltyGuard {
  /*//////////////////////////////////////////////////////////////////////////
                            Events
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Emitted when deadman trigger datetime has been updated.
  event DeadmanTriggerDatetimeUpdated(address indexed _updater, uint256 _oldDatetime, uint256 _newDatetime);

  /// @notice Emitted when the deadman switch is activated.
  event DeadmanTriggerActivated(address indexed _activator);

  /*//////////////////////////////////////////////////////////////////////////
                          Custom Errors
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Emitted when the deadman trigger datetime threshold hasnt passed but tries to get called.
  error DeadmanTriggerStillActive();

  /*//////////////////////////////////////////////////////////////////////////
                          External Write Functions
  //////////////////////////////////////////////////////////////////////////*/

  /// @notice Sets the deadman list trigger for the specified number of years from current block timestamp
  /// @param _numYears to renew the trigger for.
  function setDeadmanListTriggerRenewalDuration(uint256 _numYears) external;

  /// @notice Triggers the deadman switch for the list
  function activateDeadmanListTrigger() external;

  /// @notice The datetime threshold after which the deadman trigger can be called by anyone.
  /// @return uint256 denoting unix epoch time after which the deadman trigger can be activated.
  function getDeadmanTriggerAvailableDatetime() external view returns (uint256);
}