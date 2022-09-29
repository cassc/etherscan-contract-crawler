// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IKeep3rJob.sol';

interface IKeep3rStealthJob is IKeep3rJob {
  // events

  /// @notice Emitted when a new StealthRelayer contract is set
  /// @param _stealthRelayer Address of the new StealthRelayer contract
  event StealthRelayerSet(address _stealthRelayer);

  // errors

  /// @notice Throws when a OnlyStealthRelayer function is called from an unknown address
  error OnlyStealthRelayer();

  // views

  /// @return _stealthRelayer Address of the StealthRelayer contract
  function stealthRelayer() external view returns (address _stealthRelayer);

  // methods

  /// @notice Allows governor to set a new StealthRelayer contract
  /// @param _stealthRelayer Address of the new StealthRelayer contract
  function setStealthRelayer(address _stealthRelayer) external;
}