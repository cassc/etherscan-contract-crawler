// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'hardhat/console.sol';

library Months {
  bytes private constant DAYS_PER_MONTH = hex"1f1c1f1e1f1e1f1f1e1f1e1f";

  struct Month {
    uint32 month;
    uint32 len;
    uint end;
  }

  function monthDays(uint8 m, bool leap_year) private pure returns (uint8) {
    if (m == 2) return leap_year ? 29 : 28;
    return uint8(DAYS_PER_MONTH[uint(m - 1)]);
  }

  function isLeap(uint year) private pure returns (bool) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  }

  function nextMonth(Month memory month) internal pure returns (Month memory) {
    uint32 next = month.month + 1;
    uint8 m = uint8(next % 12);
    uint32 y = next / 12;
    if (m == 0) {
      m++;
      y--;
    }
    uint32 len = monthDays(m, isLeap(y)) * 1 days;
    return Month(
      next,
      len,
      month.end + len
    );
  }

  function getMonth(uint timestamp) internal pure returns (Month memory) {
    // https://howardhinnant.github.io/date_algorithms.html#civil_from_days
    uint ds = timestamp / 1 days;
    uint z = ds + 719468;
    uint era = z / 146097;
    uint doe = z % 146097;
    uint yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    uint doy = doe - (yoe * 365 + yoe / 4 - yoe / 100);
    uint mp = (doy * 5 + 2) / 153;
    uint8 m = uint8(mp < 10 ? mp + 3 : mp - 9);
    uint y = era * 400 + yoe + (m <= 2 ? 1 : 0);
    uint start = (ds + (mp * 153 + 2) / 5 - doy) * 1 days;
    uint32 len = monthDays(m, isLeap(y)) * 1 days;

    return Month(
      uint32(y * 12 + m),
      len,
      start + len - 1
    );
  }
}