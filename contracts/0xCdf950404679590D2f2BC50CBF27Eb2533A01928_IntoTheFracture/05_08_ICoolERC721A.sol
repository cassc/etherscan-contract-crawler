// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICoolERC721A {
  /// @notice Mint an amount of tokens to the given address
  /// @dev Can only be called by an account with the MINTER_ROLE
  ///      Will revert if called when paused, see _beforeTokenTransfer
  /// @param to The address to mint the token to
  /// @param amount The amount of tokens to mint
  function mint(address to, uint256 amount) external;

  /// @notice Externally exposes the _nextTokenId function
  /// @dev used for referencing when burning fractures
  /// @return The next token id
  function nextTokenId() external view returns (uint256);
}