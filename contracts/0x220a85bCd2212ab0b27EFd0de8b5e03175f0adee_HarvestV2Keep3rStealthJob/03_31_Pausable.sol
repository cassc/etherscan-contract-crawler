// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import './Governable.sol';
import '../../interfaces/utils/IPausable.sol';

abstract contract Pausable is IPausable, Governable {
  /// @inheritdoc IPausable
  bool public paused;

  // setters

  /// @inheritdoc IPausable
  function setPause(bool _paused) external onlyGovernor {
    _setPause(_paused);
  }

  // modifiers

  modifier notPaused() {
    if (paused) revert Paused();
    _;
  }

  // internals

  function _setPause(bool _paused) internal {
    if (paused == _paused) revert NoChangeInPause();
    paused = _paused;
    emit PauseSet(_paused);
  }
}