// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

/// @notice Helper interface for checking fTokens.
interface ICTokenLike {
  function isCToken() external returns (bool);

  function underlying() external view returns (address);
}

/// @notice Helper interface for interacting with underlying assets
///         that are ERC20 compliant
interface IERC20Like {
  function decimals() external view returns (uint8);
}