// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

enum Timezone {
  UNIVERSAL,
  WESTERN,
  EASTERN
}

library Calendar {
  uint256 internal constant START = 1640995200; // -> 01/01/2022 12:00 AM UTC

  function night(Timezone timezone) internal view returns (bool) {
    uint256 start = timezone == Timezone.UNIVERSAL ? START : timezone == Timezone.WESTERN
      ? START + 5 hours
      : START - 5 hours;

    uint256 elapsedToday = (block.timestamp - start) % 1 days;

    return elapsedToday < 6 hours || elapsedToday >= 18 hours;
  }
}