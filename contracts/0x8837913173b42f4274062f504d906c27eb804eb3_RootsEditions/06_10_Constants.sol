// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

uint256 constant EDITION_SIZE = 20;
uint256 constant EDITION_RELEASE_SCHEDULE = 24 hours;

uint256 constant PRESALE_PERIOD = 48 hours;
uint256 constant EDITION_SALE_PERIOD = EDITION_RELEASE_SCHEDULE * EDITION_SIZE;
uint256 constant UNSOLD_TIMELOCK = EDITION_SALE_PERIOD + 10 days;
uint256 constant PRINT_CLAIM_PERIOD = UNSOLD_TIMELOCK + 30 days;
uint256 constant REAL_ID_MULTIPLIER = 100;