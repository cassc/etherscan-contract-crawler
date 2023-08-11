// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library Errors {
    string public constant USER_WITHDRAW_INSUFFICIENT_VT = "1";
    string public constant VAULT_DEPOSIT = "2";
    string public constant VAULT_WITHDRAW = "3";
    string public constant EMPTY_STRING = "4";
    string public constant RISK_PROFILE_EXISTS = "5";
    string public constant NOT_A_CONTRACT = "6";
    string public constant TOKEN_NOT_APPROVED = "7";
    string public constant EOA_NOT_WHITELISTED = "8";
    string public constant INSUFFICIENT_OUTPUT_AMOUNT = "9";
    string public constant MINIMUM_USER_DEPOSIT_VALUE_UT = "10";
    string public constant TOTAL_VALUE_LOCKED_LIMIT_UT = "11";
    string public constant USER_DEPOSIT_CAP_UT = "12";
    string public constant VAULT_EMERGENCY_SHUTDOWN = "13";
    string public constant VAULT_PAUSED = "14";
    string public constant ADMIN_CALL = "15";
    string public constant EMERGENCY_BRAKE = "16";
    string public constant UNDERLYING_TOKENS_HASH_EXISTS = "17";
    string public constant TRANSFER_TO_THIS_CONTRACT = "18";
    string public constant UNDERLYING_TOKEN_APPROVED = "19";
    string public constant CLAIM_REWARD_FAILED = "20";
    string public constant NOTHING_TO_CLAIM = "21";
    string public constant PERMIT_FAILED = "22";
    string public constant PERMIT_LEGACY_FAILED = "23";
    string public constant AMOUNT_EXCEEDS_ALLOWANCE = "24";
    string public constant ZERO_ADDRESS_NOT_VALID = "25";
    string public constant INVALID_EXPIRATION = "26";
    string public constant INVALID_SIGNATURE = "27";
    string public constant LENGTH_MISMATCH = "28";
}