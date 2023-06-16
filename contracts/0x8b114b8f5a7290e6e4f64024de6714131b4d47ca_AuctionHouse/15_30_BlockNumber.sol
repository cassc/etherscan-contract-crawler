// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

/// @title Function for getting block number
/// @dev Base contract that is overridden for tests
abstract contract BlockNumber {
  /// @dev Method that exists purely to be overridden for tests
  /// @return The current block number
  function _blockNumber() internal view virtual returns (uint256) {
    return block.number;
  }
}