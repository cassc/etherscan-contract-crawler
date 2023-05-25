// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IBaseErrors.sol';

interface IGovernable is IBaseErrors {
  // events
  event PendingGovernorSet(address _governor, address _pendingGovernor);
  event PendingGovernorAccepted(address _newGovernor);

  // errors
  error OnlyGovernor();
  error OnlyPendingGovernor();

  // variables
  function governor() external view returns (address _governor);

  function pendingGovernor() external view returns (address _pendingGovernor);

  // methods
  function setPendingGovernor(address _pendingGovernor) external;

  function acceptPendingGovernor() external;
}