// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ----------------------------------------------------------------------------
// Subset of BokkyPooBah's DateTime Library v1.00
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

library TimeLib {
  uint constant SECONDS_PER_DAY = 24 * 60 * 60;
  uint constant SECONDS_PER_HOUR = 60 * 60;
  uint constant SECONDS_PER_MINUTE = 60;
  int constant OFFSET19700101 = 2440588;

  function _daysToDate(
    uint _days
  ) internal pure returns (uint year, uint month, uint day) {
    int __days = int(_days);

    int L = __days + 68569 + OFFSET19700101;
    int N = (4 * L) / 146097;
    L = L - (146097 * N + 3) / 4;
    int _year = (4000 * (L + 1)) / 1461001;
    L = L - (1461 * _year) / 4 + 31;
    int _month = (80 * L) / 2447;
    int _day = L - (2447 * _month) / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    year = uint(_year);
    month = uint(_month);
    day = uint(_day);
  }

  function getYear(uint timestamp) internal pure returns (uint year) {
    uint month;
    uint day;
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getMonth(uint timestamp) internal pure returns (uint month) {
    uint year;
    uint day;
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getDay(uint timestamp) internal pure returns (uint day) {
    uint year;
    uint month;
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getHour(uint timestamp) internal pure returns (uint hour) {
    uint secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
  }

  function getMinute(uint timestamp) internal pure returns (uint minute) {
    uint secs = timestamp % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
  }

  function getSecond(uint timestamp) internal pure returns (uint second) {
    second = timestamp % SECONDS_PER_MINUTE;
  }
}