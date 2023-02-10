// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IGovernable.sol';

interface IKeep3rJob is IGovernable {
  // events

  /// @notice Emitted when a new Keep3r contract is set
  /// @param _keep3r Address of the new Keep3r contract
  event Keep3rSet(address _keep3r);

  // errors

  /// @notice Throws when a keeper fails the validation
  error KeeperNotValid();

  // views

  /// @return _keep3r Address of the Keep3r contract
  function keep3r() external view returns (address _keep3r);

  // methods

  /// @notice Allows governor to set a new Keep3r contract
  /// @param _keep3r Address of the new Keep3r contract
  function setKeep3r(address _keep3r) external;
}