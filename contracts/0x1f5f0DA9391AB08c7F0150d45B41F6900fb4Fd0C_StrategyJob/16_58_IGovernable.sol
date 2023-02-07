// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

/// @title Governable contract
/// @notice Manages the governance role
interface IGovernable {
  // Events

  /// @notice Emitted when pendingGovernance accepts to be governance
  /// @param _governance Address of the new governance
  event GovernanceSet(address _governance);

  /// @notice Emitted when a new governance is proposed
  /// @param _pendingGovernance Address that is proposed to be the new governance
  event GovernanceProposal(address _pendingGovernance);

  // Errors

  /// @notice Throws if the caller of the function is not governance
  error OnlyGovernance();

  /// @notice Throws if the caller of the function is not pendingGovernance
  error OnlyPendingGovernance();

  /// @notice Throws if trying to set governance to zero address
  error NoGovernanceZeroAddress();

  // Variables

  /// @notice Stores the governance address
  /// @return _governance The governance addresss
  function governance() external view returns (address _governance);

  /// @notice Stores the pendingGovernance address
  /// @return _pendingGovernance The pendingGovernance addresss
  function pendingGovernance() external view returns (address _pendingGovernance);

  // Methods

  /// @notice Proposes a new address to be governance
  /// @param _governance The address being proposed as the new governance
  function setGovernance(address _governance) external;

  /// @notice Changes the governance from the current governance to the previously proposed address
  function acceptGovernance() external;
}