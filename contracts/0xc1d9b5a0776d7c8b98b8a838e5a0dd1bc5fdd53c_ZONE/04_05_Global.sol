// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

library GLOBAL {
    uint256 constant SECONDS_IN_YEAR = 365 * 24 * 3600; // 365 days * 24 hours * 60 minutes * 60 seconds
    uint256 constant SECONDS_IN_QUARTER = SECONDS_IN_YEAR / 4;
    uint256 constant SECONDS_IN_MONTH = 30 * 24 * 3600; // 30 days * 24 hours * 60 minutes * 60 seconds

    uint8 constant QUARTERS_IN_YEAR = 4;
}