// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

interface IL2Sender {
  /**
   * @notice Sends ready task instruction to L2 executor
   * @param _task - task ID to ready
   */
  function readyTask(uint256 _task) external returns (uint256);
}