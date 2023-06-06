// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

///@dev unit scaled used to convert amounts.
uint256 constant UNIT = 10 ** 6;

// Placeholder uint value to prevent cold writes
uint256 constant PLACEHOLDER_UINT = 1;

// Fees are 18-decimal places. For example: 20 * 10**18 = 20%
uint256 constant PERCENT_MULTIPLIER = 10 ** 18;

uint32 constant SECONDS_PER_DAY = 86400;
uint32 constant DAYS_PER_YEAR = 365;