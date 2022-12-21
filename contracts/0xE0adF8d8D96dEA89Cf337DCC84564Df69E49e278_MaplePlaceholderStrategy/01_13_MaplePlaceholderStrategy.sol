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
  function _balanceOf() internal view override returns (uint256) {}
}