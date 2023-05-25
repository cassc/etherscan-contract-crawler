// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface IEpochUtils {
  function epochPeriodInSeconds() external view returns (uint256);

  function firstEpochStartTime() external view returns (uint256);

  function getCurrentEpochNumber() external view returns (uint256);

  function getEpochNumber(uint256 timestamp) external view returns (uint256);
}