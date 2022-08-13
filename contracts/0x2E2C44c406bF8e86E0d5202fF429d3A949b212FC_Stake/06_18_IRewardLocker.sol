// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;

interface IRewardLocker {
  /**
   * @dev queue a vesting schedule
   */
  function lockWithStartBlock(
    address token,
    address account,
    uint256 quantity,
    uint256 startBlock
  ) external payable;
}