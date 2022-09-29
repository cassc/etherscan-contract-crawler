// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import './IV2KeeperJob.sol';

interface IV2Keep3rStealthJob is IV2KeeperJob {
  /// @notice Function to be called by governor or mechanic that triggers the execution of the given strategy
  /// @notice This function bypasses the stealth relayer checks
  /// @param _strategy Address of the strategy to be worked
  function forceWorkUnsafe(address _strategy) external;
}