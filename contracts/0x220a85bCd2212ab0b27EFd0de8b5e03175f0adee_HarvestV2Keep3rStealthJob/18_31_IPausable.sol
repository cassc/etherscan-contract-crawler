// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IGovernable.sol';

interface IPausable is IGovernable {
  // events

  /// @notice Emitted when the contract pause is switched
  /// @param _paused Whether the contract is paused or not
  event PauseSet(bool _paused);

  // errors

  /// @notice Throws when a keeper tries to work a paused contract
  error Paused();

  /// @notice Throws when governor tries to switch pause to the same state as before
  error NoChangeInPause();

  // views

  /// @return _paused Whether the contract is paused or not
  function paused() external view returns (bool _paused);

  // methods

  /// @notice Allows governor to pause or unpause the contract
  /// @param _paused Whether the contract should be paused or not
  function setPause(bool _paused) external;
}