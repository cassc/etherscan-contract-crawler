// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

library IntervalUtils {
  /// @notice Thrown when a user tries get the description of an unsupported interval
  error InvalidInterval();

  function intervalToDescription(uint32 _swapInterval) internal pure returns (string memory) {
    if (_swapInterval == 1 minutes) return 'Every minute';
    if (_swapInterval == 5 minutes) return 'Every 5 minutes';
    if (_swapInterval == 15 minutes) return 'Every 15 minutes';
    if (_swapInterval == 30 minutes) return 'Every 30 minutes';
    if (_swapInterval == 1 hours) return 'Hourly';
    if (_swapInterval == 4 hours) return 'Every 4 hours';
    if (_swapInterval == 1 days) return 'Daily';
    if (_swapInterval == 1 weeks) return 'Weekly';
    revert InvalidInterval();
  }
}