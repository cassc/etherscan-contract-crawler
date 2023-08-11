// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/**
 * @title library for Errors mapping
 * @author Souq.Finance
 * @notice Defines the output of error messages reverted by the contracts of the Souq protocol
 * @notice License: https://souq-nft-amm-v1.s3.amazonaws.com/LICENSE.md
 */
library Errors {
    string public constant ADDRESS_IS_ZERO = "ADDRESS_IS_ZERO";
    string public constant NOT_ENOUGH_USER_BALANCE = "NOT_ENOUGH_USER_BALANCE";
    string public constant NOT_ENOUGH_APPROVED = "NOT_ENOUGH_APPROVED";
    string public constant INVALID_AMOUNT = "INVALID_AMOUNT";
    string public constant AMM_PAUSED = "AMM_PAUSED";
    string public constant VAULT_PAUSED = "VAULT_PAUSED";
    string public constant FLASHLOAN_DISABLED = "FLASHLOAN_DISABLED";
    string public constant ADDRESSES_REGISTRY_NOT_SET = "ADDRESSES_REGISTRY_NOT_SET";
    string public constant UPGRADEABILITY_DISABLED = "UPGRADEABILITY_DISABLED";
    string public constant CALLER_NOT_UPGRADER = "CALLER_NOT_UPGRADER";
    string public constant CALLER_NOT_POOL_ADMIN = "CALLER_NOT_POOL_ADMIN";
    string public constant CALLER_NOT_ACCESS_ADMIN = "CALLER_NOT_ACCESS_ADMIN";
    string public constant CALLER_NOT_POOL_ADMIN_OR_OPERATIONS = "CALLER_NOT_POOL_ADMIN_OR_OPERATIONS";
    string public constant CALLER_NOT_ORACLE_ADMIN = "CALLER_NOT_ORACLE_ADMIN";
    string public constant CALLER_NOT_TIMELOCK = "CALLER_NOT_TIMELOCK";
    string public constant CALLER_NOT_TIMELOCK_ADMIN = "CALLER_NOT_TIMELOCK_ADMIN";
    string public constant ADDRESS_IS_PROXY = "ADDRESS_IS_PROXY";
    string public constant ARRAY_NOT_SAME_LENGTH = "ARRAY_NOT_SAME_LENGTH";
    string public constant NO_SUB_POOL_AVAILABLE = "NO_SUB_POOL_AVAILABLE";
    string public constant LIQUIDITY_MODE_RESTRICTED = "LIQUIDITY_MODE_RESTRICTED";
    string public constant TVL_LIMIT_REACHED = "TVL_LIMIT_REACHED";
    string public constant CALLER_MUST_BE_POOL = "CALLER_MUST_BE_POOL";
    string public constant CANNOT_RESCUE_POOL_TOKEN = "CANNOT_RESCUE_POOL_TOKEN";
    string public constant CALLER_MUST_BE_STABLEYIELD_ADMIN = "CALLER_MUST_BE_STABLEYIELD_ADMIN";
    string public constant CALLER_MUST_BE_STABLEYIELD_LENDER = "CALLER_MUST_BE_STABLEYIELD_LENDER";
    string public constant FUNCTION_REQUIRES_ACCESS_NFT = "FUNCTION_REQUIRES_ACCESS_NFT";
    string public constant FEE_OUT_OF_BOUNDS = "FEE_OUT_OF_BOUNDS";
    string public constant ONLY_ADMIN_CAN_ADD_LIQUIDITY = "ONLY_ADMIN_CAN_ADD_LIQUIDITY";
    string public constant NOT_ENOUGH_POOL_RESERVE = "NOT_ENOUGH_POOL_RESERVE";
    string public constant NOT_ENOUGH_SUBPOOL_RESERVE = "NOT_ENOUGH_SUBPOOL_RESERVE";
    string public constant NOT_ENOUGH_SUBPOOL_SHARES = "NOT_ENOUGH_SUBPOOL_SHARES";
    string public constant SUBPOOL_DISABLED = "SUBPOOL_DISABLED";
    string public constant ADDRESS_NOT_CONNECTOR_ADMIN = "ADDRESS_NOT_CONNECTOR_ADMIN";
    string public constant WITHDRAW_LIMIT_REACHED = "WITHDRAW_LIMIT_REACHED";
    string public constant DEPOSIT_LIMIT_REACHED = "DEPOSIT_LIMIT_REACHED";
    string public constant SHARES_VALUE_EXCEEDS_TARGET = "SHARES_VALUE_EXCEEDS_TARGET";
    string public constant SHARES_VALUE_BELOW_TARGET = "SHARES_VALUE_BELOW_TARGET";
    string public constant LP_VALUE_BELOW_TARGET = "LP_VALUE_BELOW_TARGET";
    string public constant SHARES_TARGET_EXCEEDS_RESERVE = "SHARES_TARGET_EXCEEDS_RESERVE";
    string public constant SWAPPING_SHARES_TEMPORARY_DISABLED_DUE_TO_LOW_CONDITIONS =
        "SWAPPING_SHARES_TEMPORARY_DISABLED_DUE_TO_LOW_CONDITIONS";
    string public constant ADDING_SHARES_TEMPORARY_DISABLED_DUE_TO_LOW_CONDITIONS =
        "ADDING_SHARES_TEMPORARY_DISABLED_DUE_TO_LOW_CONDITIONS";
    string public constant UPGRADE_DISABLED = "UPGRADE_DISABLED";
    string public constant USER_CANNOT_BE_CONTRACT = "USER_CANNOT_BE_CONTRACT";
    string public constant DEADLINE_NOT_FOUND = "DEADLINE_NOT_FOUND";
    string public constant FLASHLOAN_PROTECTION_ENABLED = "FLASHLOAN_PROTECTION_ENABLED";
    string public constant INVALID_POOL_ADDRESS = "INVALID_POOL_ADDRESS";
    string public constant INVALID_SUBPOOL_ID = "INVALID_SUBPOOL_ID";
    string public constant INVALID_YIELD_DISTRIBUTOR_ADDRESS = "INVALID_YIELD_DISTRIBUTOR_ADDRESS";
    string public constant YIELD_DISTRIBUTOR_NOT_FOUND = "YIELD_DISTRIBUTOR_NOT_FOUND";
    string public constant INVALID_TOKEN_ID = "INVALID_TOKEN_ID";
    string public constant INVALID_VAULT_ADDRESS = "INVALID_VAULT_ADDRESS";
    string public constant VAULT_NOT_FOUND = "VAULT_NOT_FOUND";
    string public constant INVALID_TOKEN_ADDRESS = "INVALID_TOKEN_ADDRESS";
    string public constant INVALID_STAKING_CONTRACT = "INVALID_STAKING_CONTRACT";
    string public constant STAKING_CONTRACT_NOT_FOUND = "STAKING_CONTRACT_NOT_FOUND";
    string public constant INVALID_SWAP_CONTRACT = "INVALID_SWAP_CONTRACT";
    string public constant SWAP_CONTRACT_NOT_FOUND = "SWAP_CONTRACT_NOT_FOUND";
    string public constant INVALID_ORACLE_CONNECTOR = "INVALID_ORACLE_CONNECTOR";
    string public constant ORACLE_CONNECTOR_NOT_FOUND = "ORACLE_CONNECTOR_NOT_FOUND";
    string public constant INVALID_COLLECTION_CONTRACT = "INVALID_COLLECTION_CONTRACT";
    string public constant COLLECTION_CONTRACT_NOT_FOUND = "COLLECTION_CONTRACT_NOT_FOUND";
    string public constant INVALID_STABLECOIN_YIELD_CONNECTOR = "INVALID_STABLECOIN_YIELD_CONNECTOR";
    string public constant STABLECOIN_YIELD_CONNECTOR_NOT_FOUND = "STABLECOIN_YIELD_CONNECTOR_NOT_FOUND";
    string public constant TIMELOCK_USES_ACCESS_CONTROL = "TIMELOCK_USES_ACCESS_CONTROL";
    string public constant TIMELOCK_ETA_MUST_SATISFY_DELAY = "TIMELOCK_ETA_MUST_SATISFY_DELAY";
    string public constant TIMELOCK_TRANSACTION_NOT_READY = "TIMELOCK_TRANSACTION_NOT_READY";
    string public constant TIMELOCK_TRANSACTION_ALREADY_EXECUTED = "TIMELOCK_TRANSACTION_ALREADY_EXECUTED";
    string public constant TIMELOCK_TRANSACTION_ALREADY_QUEUED = "TIMELOCK_TRANSACTION_ALREADY_QUEUED";
    string public constant APPROVAL_FAILED = "APPROVAL_FAILED";
    string public constant DISCOUNT_EXCEEDS_100 = "DISCOUNT_EXCEEDS_100";
}