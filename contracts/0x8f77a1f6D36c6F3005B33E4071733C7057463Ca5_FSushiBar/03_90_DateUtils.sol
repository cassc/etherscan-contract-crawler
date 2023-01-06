// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

uint256 constant WEEK = 1 weeks;

library DateUtils {
    function toWeekNumber(uint256 timestamp) internal pure returns (uint256) {
        return timestamp / WEEK;
    }

    function toTimestamp(uint256 weekNumber) internal pure returns (uint256) {
        return weekNumber * WEEK;
    }
}