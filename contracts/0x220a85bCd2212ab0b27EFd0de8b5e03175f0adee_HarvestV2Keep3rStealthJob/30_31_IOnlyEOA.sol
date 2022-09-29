// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IOnlyEOA {
  // events

  /// @notice Emitted when onlyEOA is set
  event OnlyEOASet(bool _onlyEOA);

  // errors

  /// @notice Throws when keeper is not tx.origin
  error OnlyEOA();

  // views

  /// @return _onlyEOA Whether the keeper is required to be an EOA or not
  function onlyEOA() external returns (bool _onlyEOA);

  // methods

  /// @notice Allows governor to set the onlyEOA condition
  /// @param _onlyEOA Whether the keeper is required to be an EOA or not
  function setOnlyEOA(bool _onlyEOA) external;
}