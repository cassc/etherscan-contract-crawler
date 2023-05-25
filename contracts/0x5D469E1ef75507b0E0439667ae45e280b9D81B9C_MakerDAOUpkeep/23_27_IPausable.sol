// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IGovernable.sol';

interface IPausable is IGovernable {
  // events
  event PauseSet(bool _paused);

  // errors
  error NoChangeInPause();

  // variables
  function paused() external view returns (bool _paused);

  // methods
  function setPause(bool _paused) external;
}