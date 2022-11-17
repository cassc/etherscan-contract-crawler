// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

uint256 constant SECONDS_IN_THE_YEAR = 365 * 24 * 60 * 60; // 365 days * 24 hours * 60 minutes * 60 seconds
uint256 constant DAYS_IN_THE_YEAR = 365;
uint256 constant MAX_INT = type(uint256).max;

uint256 constant DECIMALS18 = 10**18;

uint256 constant PRECISION = 10**25;
uint256 constant PERCENTAGE_100 = 100 * PRECISION;

uint256 constant BLOCKS_PER_DAY = 7200;
uint256 constant BLOCKS_PER_YEAR = BLOCKS_PER_DAY * 365;

uint256 constant BLOCKS_PER_DAY_BSC = 28800;
uint256 constant BLOCKS_PER_DAY_POLYGON = 43200;

uint256 constant APY_TOKENS = DECIMALS18;

uint256 constant PROTOCOL_PERCENTAGE = 20 * PRECISION;

uint256 constant DEFAULT_REBALANCING_THRESHOLD = 10**23;

uint256 constant EPOCH_DAYS_AMOUNT = 7;

// ClaimVoting ClaimingRegistry
uint256 constant APPROVAL_PERCENTAGE = 66 * PRECISION;
uint256 constant PENALTY_THRESHOLD = 11 * PRECISION;
uint256 constant QUORUM = 10 * PRECISION;
uint256 constant CALCULATION_REWARD_PER_DAY = PRECISION;
uint256 constant PERCENTAGE_50 = 50 * PRECISION;

// PolicyBook
uint256 constant MINUMUM_COVERAGE = 100 * DECIMALS18; // 100 STBL
uint256 constant ANNUAL_COVERAGE_TOKENS = MINUMUM_COVERAGE * 10; // 1000 STBL

uint256 constant PREMIUM_DISTRIBUTION_EPOCH = 1 days;
uint256 constant MAX_PREMIUM_DISTRIBUTION_EPOCHS = 90;
enum Networks {ETH, BSC, POL}