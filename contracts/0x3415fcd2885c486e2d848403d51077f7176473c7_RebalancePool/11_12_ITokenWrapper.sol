// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface ITokenWrapper {
  /// @notice Return the address of source token.
  function src() external view returns (address);

  /// @notice Return the address of destination token.
  function dst() external view returns (address);

  /// @notice Wrap some `src` token to `dst` token.
  ///
  /// @dev Assume that the token is already transfered to this contract.
  ///
  /// @param amount The amount of `src` token to wrap.
  /// @return uint256 The amount of `dst` token received.
  function wrap(uint256 amount) external returns (uint256);

  /// @notice Unwrap some `dst` token to `src` token.
  ///
  /// @dev Assume that the token is already transfered to this contract.
  ///
  /// @param amount The amount of `dst` token to unwrap.
  /// @return uint256 The amount of `src` token received.
  function unwrap(uint256 amount) external returns (uint256);
}