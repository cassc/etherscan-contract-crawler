//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8 <0.9.0;

import {IGovernable} from '../../interfaces/peripherals/IGovernable.sol';

abstract contract Governable is IGovernable {
  /// @inheritdoc IGovernable
  address public governor;

  /// @inheritdoc IGovernable
  address public pendingGovernor;

  constructor(address _governor) {
    if (_governor == address(0)) revert ZeroAddress();
    governor = _governor;
  }

  /// @inheritdoc IGovernable
  function setPendingGovernor(address _pendingGovernor) external onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  /// @inheritdoc IGovernable
  function acceptPendingGovernor() external onlyPendingGovernor {
    _acceptPendingGovernor();
  }

  function _setPendingGovernor(address _pendingGovernor) internal {
    if (_pendingGovernor == address(0)) revert ZeroAddress();
    pendingGovernor = _pendingGovernor;
    emit PendingGovernorSet(governor, pendingGovernor);
  }

  function _acceptPendingGovernor() internal {
    governor = pendingGovernor;
    pendingGovernor = address(0);
    emit PendingGovernorAccepted(governor);
  }

  modifier onlyGovernor() {
    if (msg.sender != governor) revert OnlyGovernor();
    _;
  }

  modifier onlyPendingGovernor() {
    if (msg.sender != pendingGovernor) revert OnlyPendingGovernor();
    _;
  }
}