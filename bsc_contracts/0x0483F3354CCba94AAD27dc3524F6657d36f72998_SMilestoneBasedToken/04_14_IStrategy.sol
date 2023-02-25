// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IStrategy {
  /// @dev Throws if admin tries to set address of ContractRegistry to ZERO_ADDRESS
  error ZeroAddress();

  /// @dev Throws when both addresses(from, to) which passed to method validateTransaction
  /// are not registred in WhiteList contract
  error InvalidAddresses();

  /// @notice Emits when the administrator updates address of Registry contract.
  /// @param newRegistry address of new Registry contract.
  event UpdatedRegistry(address indexed newRegistry);

  /// @notice Set new address of ContractRegistry contract.
  /// @param registry_ new address of ContractRegistry contract.
  function setRegistry(address registry_) external;

  /// @notice Validate transaction by checking addresses "from" and "to".
  /// @param from address of sender transaction;
  /// @param to address of recipient of sMILE tokens.
  function validateTransaction(
    address from,
    address to,
    uint256 /* amount */
  ) external view;
}