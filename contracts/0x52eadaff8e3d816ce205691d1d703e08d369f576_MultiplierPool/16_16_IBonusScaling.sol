// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface IBonusScaling {
  /**
   * Scale staked seconds according to multiplier
   */
  struct BonusScaling {
    // [e18] Minimum bonus amount
    uint256 min;
    // [e18] Maximum bonus amount
    uint256 max;
    // [seconds] Period over which to apply bonus scaling
    uint256 period;
  }
}