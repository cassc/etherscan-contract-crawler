// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './Governable.sol';
import '../../interfaces/utils/IPausable.sol';

abstract contract Pausable is IPausable, Governable {
  bool public override paused;

  function setPause(bool _paused) external override onlyGovernor {
    if (paused == _paused) revert NoChangeInPause();
    paused = _paused;
    emit PauseSet(_paused);
  }
}