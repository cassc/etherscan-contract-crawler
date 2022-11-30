// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;

import '../IERC20Metadata.sol';

/// @title Pre-IDO state that never changes
/// @notice These parameters are fixed for a pre-IDO forever, i.e., the methods will always return the same values
interface IPreIDOImmutables {
  /// @notice The token contract that used to distribute to investors when those tokens is unlocked
  /// @return The token contract
  function token() external view returns(IERC20Metadata);
}