// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title An interface that allows a contract to listen to token mint, transfer and burn events.
interface IPeriodicPrizeStrategy is IERC165 {
  function awardNotInProgress() external view returns (bool);
  function prizePeriodRemainingSeconds() external view returns (uint256);
  function prizePeriodSeconds() external view returns (uint256);
  function prizePeriodStartedAt() external view returns (uint256);
  function prizePeriodEndAt() external view returns (uint256);
}