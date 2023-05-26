// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

library LibTime {

    // 7 * 86400 seconds - all future times are rounded by week
    uint256 public constant DAY = 86400;
    uint256 public constant WEEK = DAY * 7;

    /**
     * @dev times are rounded by week
     * @param time time
     */
    function timesRoundedByWeek(uint256 time) internal pure returns (uint256) {
        return (time / WEEK) * WEEK;
    }
}