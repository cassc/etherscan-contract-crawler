// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './base/BaseStrategy.sol';

import '../interfaces/maple/IPool.sol';
import '../interfaces/maple/IMplRewards.sol';

contract MaplePlaceholderStrategy is BaseStrategy {
  // Our MapleStrategy at `0xB2acd0214F87d217A2eF148aA4a5ABA71d3F7956` is connected to Maple V1
  // MapleV1 suffered a type of loss that the Maple contracts were not able to handle
  // It is expected that at least 1M USDC (of the 5M) will be recovered soon
  // This strategy will act like that 1M USDC is already there, fixing the accounting of the Sherlock pool
  // Once the 1M USDC is recovered this strategy will be deleted and the 1M will be added to the pool

  uint256 immutable EXPECTED_BALANCE = 1_000_000 * 10**6;

  constructor(IMaster _initialParent) BaseNode(_initialParent) {}

  /// @notice Signal if strategy is ready to be used
  /// @return Boolean indicating if strategy is ready
  function setupCompleted() external view override returns (bool) {
    return true;
  }

  /// @notice Override deposit function to implement interface
  function _deposit() internal override whenNotPaused {}

  /// @notice Override withdrawAll function to implement interface
  function _withdrawAll() internal override returns (uint256 amount) {}

  /// @notice Override withdraw function to implement interface
  /// @param _amount Amount of USDC to withdraw
  function _withdraw(uint256 _amount) internal override {}

  /// @notice Return placeholder balance of USDC that is expected to be recovered
  function _balanceOf() internal view override returns (uint256) {
    return EXPECTED_BALANCE;
  }
}