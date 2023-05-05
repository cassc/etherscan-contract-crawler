// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IBaseErrors.sol';

interface IGovernable is IBaseErrors {
  // events
  /// @notice Emitted when a new governance is proposed
  event PendingGovernorSet(address _governor, address _pendingGovernor);
  /// @notice Emitted when pendingGovernance accepts to be governance
  event PendingGovernorAccepted(address _newGovernor);

  // errors
  /// @notice Throws if the caller of the function is not Governance
  error OnlyGovernor();
  /// @notice Throws if the caller of the function is not pendingGovernance
  error OnlyPendingGovernor();

  // variables
  /// @notice Stores the governance address
  /// @return _governor The governance addresss
  function governor() external view returns (address _governor);

  /// @notice Stores the pendingGovernance address
  /// @return _pendingGovernor The pendingGovernance addresss
  function pendingGovernor() external view returns (address _pendingGovernor);

  // methods
  /// @notice Proposes a new address to be governance
  /// @param _pendingGovernor The address being proposed as the new governance
  function setPendingGovernor(address _pendingGovernor) external;

  /// @notice Changes the governance from the current governance to the previously proposed address
  function acceptPendingGovernor() external;
}