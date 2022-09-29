// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IKeep3rJob.sol';

interface IKeep3rBondedJob is IKeep3rJob {
  // events

  /// @notice Emitted when a new set of requirements is set
  /// @param _bond Address of the token required to bond to work the job
  /// @param _minBond Amount of tokens required to bond to work the job
  /// @param _earned Amount of KP3R earnings required to work the job
  /// @param _age Amount of seconds since keeper registration required to work the job
  event Keep3rRequirementsSet(address _bond, uint256 _minBond, uint256 _earned, uint256 _age);

  // views

  /// @return _requiredBond Address of the token required to bond to work the job
  function requiredBond() external view returns (address _requiredBond);

  /// @return _requiredMinBond Amount of tokens required to bond to work the job
  function requiredMinBond() external view returns (uint256 _requiredMinBond);

  /// @return _requiredEarnings Amount of KP3R earnings required to work the job
  function requiredEarnings() external view returns (uint256 _requiredEarnings);

  /// @return _requiredAge Amount of seconds since keeper registration required to work the job
  function requiredAge() external view returns (uint256 _requiredAge);

  // methods

  /// @notice Allows the governor to set new requirements to work the job
  /// @param _bond Address of the token required to bond to work the job
  /// @param _minBond Amount of tokens required to bond to work the job
  /// @param _earned Amount of KP3R earnings required to work the job
  /// @param _age Amount of seconds since keeper registration required to work the job
  function setKeep3rRequirements(
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age
  ) external;
}