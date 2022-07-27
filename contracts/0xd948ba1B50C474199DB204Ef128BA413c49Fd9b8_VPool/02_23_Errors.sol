// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title Errors library
library Errors {
    string public constant INVALID_COLLATERAL_AMOUNT = "1"; // Collateral must be greater than 0 or > defined limit
    string public constant INVALID_SHARE_AMOUNT = "2"; // Share must be greater than 0
    string public constant INVALID_INPUT_LENGTH = "3"; // Input array length must be greater than 0
    string public constant INPUT_LENGTH_MISMATCH = "4"; // Input array length mismatch with another array length
    string public constant NOT_WHITELISTED_ADDRESS = "5"; // Caller is not whitelisted to withdraw without fee
    string public constant MULTI_TRANSFER_FAILED = "6"; // Multi transfer of tokens has failed
    string public constant FEE_COLLECTOR_NOT_SET = "7"; // Fee Collector is not set
    string public constant NOT_ALLOWED_TO_SWEEP = "8"; // Token is not allowed to sweep
    string public constant INSUFFICIENT_BALANCE = "9"; // Insufficient balance to performs operations to follow
    string public constant INPUT_ADDRESS_IS_ZERO = "10"; // Input address is zero
    string public constant FEE_LIMIT_REACHED = "11"; // Fee must be less than MAX_BPS
    string public constant ALREADY_INITIALIZED = "12"; // Data structure, contract, or logic already initialized and can not be called again
    string public constant ADD_IN_LIST_FAILED = "13"; // Cannot add address in address list
    string public constant REMOVE_FROM_LIST_FAILED = "14"; // Cannot remove address from address list
    string public constant STRATEGY_IS_ACTIVE = "15"; // Strategy is already active, an inactive strategy is required
    string public constant STRATEGY_IS_NOT_ACTIVE = "16"; // Strategy is not active, an active strategy is required
    string public constant INVALID_STRATEGY = "17"; // Given strategy is not a strategy of this pool
    string public constant DEBT_RATIO_LIMIT_REACHED = "18"; // Debt ratio limit reached. It must be less than MAX_BPS
    string public constant TOTAL_DEBT_IS_NOT_ZERO = "19"; // Strategy total debt must be 0
    string public constant LOSS_TOO_HIGH = "20"; // Strategy reported loss must be less than current debt
    string public constant INVALID_MAX_BORROW_LIMIT = "21"; // Max borrow limit is beyond range.
    string public constant MAX_LIMIT_LESS_THAN_MIN = "22"; // Max limit should be greater than min limit.
    string public constant INVALID_SLIPPAGE = "23"; // Slippage should be less than MAX_BPS
    string public constant WRONG_RECEIPT_TOKEN = "24"; // Wrong receipt token address
    string public constant AAVE_FLASH_LOAN_NOT_ACTIVE = "25"; // aave flash loan is not active
    string public constant DYDX_FLASH_LOAN_NOT_ACTIVE = "26"; // DYDX flash loan is not active
    string public constant INVALID_FLASH_LOAN = "27"; // invalid-flash-loan
    string public constant INVALID_INITIATOR = "28"; // "invalid-initiator"
    string public constant INCORRECT_WITHDRAW_AMOUNT = "29"; // withdrawn amount is not correct
    string public constant NO_MARKET_ID_FOUND = "30"; // dydx flash loan no marketId found for token
    string public constant SAME_AS_PREVIOUS = "31"; // Input should not be same as previous value.
    string public constant INVALID_INPUT = "32"; // Generic invalid input error code
}