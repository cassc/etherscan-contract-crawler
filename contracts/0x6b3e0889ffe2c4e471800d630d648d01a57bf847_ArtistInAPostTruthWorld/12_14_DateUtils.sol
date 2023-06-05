// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
uint256 constant SECONDS_PER_HOUR = 60 * 60;
uint256 constant SECONDS_PER_MINUTE = 60;
int256 constant OFFSET19700101 = 2440588;

library DateUtils {
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = 4 * L / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = 4000 * (L + 1) / 1461001;
            L = L - 1461 * _year / 4 + 31;
            int256 _month = 80 * L / 2447;
            int256 _day = L - 2447 * _month / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    function toDateTime(uint256 timestamp)
    internal
    pure
    returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }
}