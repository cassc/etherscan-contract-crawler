// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

interface ILyfeblocRewardLocker {
  /**
   * @dev queue a vesting schedule starting from now
   */
  function lock(
    address token,
    address account,
    uint256 amount,
    uint32 vestingDuration
  ) external payable;

  /**
   * @dev queue a vesting schedule
   */
  function lockWithStartTime(
    address token,
    address account,
    uint256 quantity,
    uint256 startTime,
    uint32 vestingDuration
  ) external payable;
}