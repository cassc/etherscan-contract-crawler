// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IStakeDAOCRVDepositor {
  function incentiveToken() external view returns (uint256);

  /// @notice Deposit & Lock Token
  /// @dev User needs to approve the contract to transfer the token
  /// @param _amount The amount of token to deposit
  /// @param _lock Whether to lock the token
  /// @param _stake Whether to stake the token
  /// @param _user User to deposit for
  function deposit(
    uint256 _amount,
    bool _lock,
    bool _stake,
    address _user
  ) external;

  /// @notice Deposits all the token of a user & locks them based on the options choosen
  /// @dev User needs to approve the contract to transfer Token tokens
  /// @param _lock Whether to lock the token
  /// @param _stake Whether to stake the token
  /// @param _user User to deposit for
  function depositAll(
    bool _lock,
    bool _stake,
    address _user
  ) external;

  /// @notice Lock forever (irreversible action) old sdveCrv to sdCrv with 1:1 rate
  /// @dev User needs to approve the contract to transfer Token tokens
  /// @param _amount amount to lock
  function lockSdveCrvToSdCrv(uint256 _amount) external;
}