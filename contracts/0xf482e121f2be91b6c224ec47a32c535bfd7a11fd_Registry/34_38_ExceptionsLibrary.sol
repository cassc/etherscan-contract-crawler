// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ExceptionsLibrary {
    string public constant ADDRESS_ZERO = "ADDRESS_ZERO";
    string public constant INCORRECT_ETH_PASSED = "INCORRECT_ETH_PASSED";
    string public constant NO_COMPANY = "NO_COMPANY";
    string public constant INVALID_TOKEN = "INVALID_TOKEN";
    string public constant NOT_POOL = "NOT_POOL";
    string public constant NOT_TGE = "NOT_TGE";
    string public constant NOT_Registry = "NOT_Registry";
    string public constant NOT_POOL_OWNER = "NOT_POOL_OWNER";
    string public constant NOT_SERVICE_OWNER = "NOT_SERVICE_OWNER";
    string public constant IS_DAO = "IS_DAO";
    string public constant NOT_DAO = "NOT_DAO";
    string public constant NOT_WHITELISTED = "NOT_WHITELISTED";
    string public constant NOT_SERVICE = "NOT_SERVICE";
    string public constant WRONG_STATE = "WRONG_STATE";
    string public constant TRANSFER_FAILED = "TRANSFER_FAILED";
    string public constant CLAIM_NOT_AVAILABLE = "CLAIM_NOT_AVAILABLE";
    string public constant NO_LOCKED_BALANCE = "NO_LOCKED_BALANCE";
    string public constant LOCKUP_TVL_REACHED = "LOCKUP_TVL_REACHED";
    string public constant HARDCAP_OVERFLOW = "HARDCAP_OVERFLOW";
    string public constant MAX_PURCHASE_OVERFLOW = "MAX_PURCHASE_OVERFLOW";
    string public constant HARDCAP_OVERFLOW_REMAINING_SUPPLY =
        "HARDCAP_OVERFLOW_REMAINING_SUPPLY";
    string public constant HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY =
        "HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY";
    string public constant MIN_PURCHASE_UNDERFLOW = "MIN_PURCHASE_UNDERFLOW";
    string public constant LOW_UNLOCKED_BALANCE = "LOW_UNLOCKED_BALANCE";
    string public constant ZERO_PURCHASE_AMOUNT = "ZERO_PURCHASE_AMOUNTs";
    string public constant NOTHING_TO_REDEEM = "NOTHING_TO_REDEEM";
    string public constant RECORD_IN_USE = "RECORD_IN_USE";
    string public constant INVALID_EIN = "INVALID_EIN";
    string public constant VALUE_ZERO = "VALUE_ZERO";
    string public constant ALREADY_SET = "ALREADY_SET";
    string public constant VOTING_FINISHED = "VOTING_FINISHED";
    string public constant ALREADY_EXECUTED = "ALREADY_EXECUTED";
    string public constant ACTIVE_TGE_EXISTS = "ACTIVE_TGE_EXISTS";
    string public constant INVALID_VALUE = "INVALID_VALUE";
    string public constant INVALID_CAP = "INVALID_CAP";
    string public constant INVALID_HARDCAP = "INVALID_HARDCAP";
    string public constant ONLY_POOL = "ONLY_POOL";
    string public constant ETH_TRANSFER_FAIL = "ETH_TRANSFER_FAIL";
    string public constant TOKEN_TRANSFER_FAIL = "TOKEN_TRANSFER_FAIL";
    string public constant SERVICE_PAUSED = "SERVICE_PAUSED";
    string public constant INVALID_PROPOSAL_TYPE = "INVALID_PROPOSAL_TYPE";
    string public constant EXECUTION_FAILED = "EXECUTION_FAILED";
    string public constant INVALID_USER = "INVALID_USER";
    string public constant NOT_LAUNCHED = "NOT_LAUNCHED";
    string public constant LAUNCHED = "LAUNCHED";
    string public constant VESTING_TVL_REACHED = "VESTING_TVL_REACHED";
    string public constant WRONG_TOKEN_ADDRESS = "WRONG_TOKEN_ADDRESS";
    string public constant GOVERNANCE_TOKEN_EXISTS = "GOVERNANCE_TOKEN_EXISTS";
    string public constant THRESHOLD_NOT_REACHED = "THRESHOLD_NOT_REACHED";
    string public constant UNSUPPORTED_TOKEN_TYPE = "UNSUPPORTED_TOKEN_TYPE";
    string public constant ALREADY_VOTED = "ALREADY_VOTED";
    string public constant ZERO_VOTES = "ZERO_VOTES";
    string public constant ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS =
        "ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS";
    string public constant EMPTY_ADDRESS = "EMPTY_ADDRESS";
    string public constant NOT_VALID_PROPOSER = "NOT_VALID_PROPOSER";
    string public constant SHARES_SUM_EXCEEDS_ONE = "SHARES_SUM_EXCEEDS_ONE";
    string public constant NOT_RESOLVER = "NOT_RESOLVER";
    string public constant NOT_REGISTRY = "NOT_REGISTRY";
    string public constant INVALID_TARGET = "INVALID_TARGET";
    string public constant NOT_TGE_FACTORY = "NOT_TGE_FACTORY";
    string public constant WRONG_AMOUNT = "WRONG_AMOUNT";
    string public constant WRONG_BLOCK_NUMBER = "WRONG_BLOCK_NUMBER";
    string public constant NOT_VALID_EXECUTOR = "NOT_VALID_EXECUTOR";
    string public constant POOL_PAUSED = "POOL_PAUSED";
    string public constant NOT_INVOICE_MANAGER = "NOT_INVOICE_MANAGER";
    string public constant WRONG_RESOLVER = "WRONG_RESOLVER";
    string public constant INVALID_PURCHASE_AMOUNT = "INVALID_PURCHASE_AMOUNT";
}