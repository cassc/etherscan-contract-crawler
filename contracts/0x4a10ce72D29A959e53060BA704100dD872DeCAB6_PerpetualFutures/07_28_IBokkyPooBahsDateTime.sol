// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBokkyPooBahsDateTime {
  function getDayOfWeek(uint256 timestamp)
    external
    pure
    returns (uint256 dayOfWeek);

  function getHour(uint256 timestamp) external pure returns (uint256 hour);
}