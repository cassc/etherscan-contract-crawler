// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

library Constants {
    uint256 internal constant YEAR_IN_SECONDS = 365 days;
    uint256 internal constant BASE = 1e18;
    uint256 internal constant MAX_FEE_PER_ANNUM = 0.05e18; // 5% max in base
    uint256 internal constant MAX_SWAP_PROTOCOL_FEE = 0.01e18; // 1% max in base
    uint256 internal constant MAX_TOTAL_PROTOCOL_FEE = 0.05e18; // 5% max in base
    uint256 internal constant MAX_P2POOL_PROTOCOL_FEE = 0.05e18; // 5% max in base
    uint256 internal constant MIN_TIME_BETWEEN_EARLIEST_REPAY_AND_EXPIRY =
        1 days;
    uint256 internal constant MAX_PRICE_UPDATE_TIMESTAMP_DIVERGENCE = 1 days;
    uint256 internal constant SEQUENCER_GRACE_PERIOD = 1 hours;
    uint256 internal constant MIN_UNSUBSCRIBE_GRACE_PERIOD = 1 days;
    uint256 internal constant MAX_UNSUBSCRIBE_GRACE_PERIOD = 14 days;
    uint256 internal constant MIN_CONVERSION_GRACE_PERIOD = 1 days;
    uint256 internal constant MIN_REPAYMENT_GRACE_PERIOD = 1 days;
    uint256 internal constant LOAN_EXECUTION_GRACE_PERIOD = 1 days;
    uint256 internal constant MAX_CONVERSION_AND_REPAYMENT_GRACE_PERIOD =
        30 days;
    uint256 internal constant MIN_TIME_UNTIL_FIRST_DUE_DATE = 1 days;
    uint256 internal constant MIN_TIME_BETWEEN_DUE_DATES = 7 days;
    uint256 internal constant MIN_WAIT_UNTIL_EARLIEST_UNSUBSCRIBE = 60 seconds;
    uint256 internal constant MAX_ARRANGER_FEE = 0.5e18; // 50% max in base
    uint256 internal constant LOAN_TERMS_UPDATE_COOL_OFF_PERIOD = 15 minutes;
    uint256 internal constant MAX_REPAYMENT_SCHEDULE_LENGTH = 20;
    uint256 internal constant SINGLE_WRAPPER_MIN_MINT = 1000; // in wei
}