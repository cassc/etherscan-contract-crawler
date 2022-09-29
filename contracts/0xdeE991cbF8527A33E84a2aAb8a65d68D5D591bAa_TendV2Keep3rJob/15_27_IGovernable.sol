// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IBaseErrors.sol';

interface IGovernable is IBaseErrors {
  // events

  /// @notice Emitted when a new pending governor is set
  /// @param _governor Address of the current governor
  /// @param _pendingGovernor Address of the proposed next governor
  event PendingGovernorSet(address _governor, address _pendingGovernor);

  /// @notice Emitted when a new governor is set
  /// @param _newGovernor Address of the new governor
  event PendingGovernorAccepted(address _newGovernor);

  // errors

  /// @notice Throws if a non-governor user tries to call a OnlyGovernor function
  error OnlyGovernor();
  /// @notice Throws if a non-pending-governor user tries to call a OnlyPendingGovernor function
  error OnlyPendingGovernor();

  // views

  /// @return _governor Address of the current governor
  function governor() external view returns (address _governor);

  /// @return _pendingGovernor Address of the current pending governor
  function pendingGovernor() external view returns (address _pendingGovernor);

  // methods

  /// @notice Allows a governor to propose a new governor
  /// @param _pendingGovernor Address of the proposed new governor
  function setPendingGovernor(address _pendingGovernor) external;

  /// @notice Allows a proposed governor to accept the governance
  function acceptPendingGovernor() external;
}