// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Errors library
 *     @author MIMO
 *     @notice Defines the error messages emtted by the different contracts of the MIMO protocol
 */
library KUMA_PROTOCOL_ERRORS {
    error CANNOT_SET_TO_ADDRESS_ZERO();
    error CANNOT_SET_TO_ZERO();
    error ERC20_TRANSFER_FROM_THE_ZERO_ADDRESS();
    error ERC20_TRANSER_TO_THE_ZERO_ADDRESS();
    error ERC20_TRANSFER_AMOUNT_EXCEEDS_BALANCE();
    error ERC20_MINT_TO_THE_ZERO_ADDRESS();
    error ERC20_BURN_FROM_THE_ZERO_ADDRESS();
    error ERC20_BURN_AMOUNT_EXCEEDS_BALANCE();
    error START_TIME_NOT_REACHED();
    error EPOCH_LENGTH_CANNOT_BE_ZERO();
    error EPOCH_LENGTH_TOO_HIGH(uint256 epochLength, uint256 maxEpochLength);
    error EPOCH_LENGTH_TOO_LOW(uint256 epochLength, uint256 minEpochLength);
    error ERROR_YIELD_LT_RAY();
    error ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(address account, bytes32 role);
    error BLACKLISTABLE_CALLER_IS_NOT_BLACKLISTER();
    error BLACKLISTABLE_ACCOUNT_IS_BLACKLISTED(address account);
    error NEW_YIELD_TOO_HIGH();
    error WRONG_RISK_CATEGORY();
    error WRONG_RISK_CONFIG();
    error INVALID_RISK_CATEGORY();
    error INVALID_TOKEN_ID();
    error ERC721_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED();
    error ERC721_APPROVAL_TO_CURRENT_OWNER();
    error ERC721_APPROVE_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED_FOR_ALL();
    error ERC721_INVALID_TOKEN_ID();
    error ERC721_CALLER_IS_NOT_TOKEN_OWNER();
    error CALLER_NOT_KUMASWAP();
    error CALLER_NOT_MIMO_BOND_TOKEN();
    error BOND_NOT_AVAILABLE_FOR_CLAIM();
    error CANNOT_SELL_MATURED_BOND();
    error NO_EXPIRED_BOND_IN_RESERVE();
    error MAX_COUPONS_REACHED();
    error COUPON_TOO_LOW();
    error CALLER_IS_NOT_MIB_TOKEN();
    error CALLER_NOT_FEE_COLLECTOR();
    error PAYEE_ALREADY_EXISTS();
    error PAYEE_DOES_NOT_EXIST();
    error PAYEES_AND_SHARES_MISMATCHED(uint256 payeeLength, uint256 shareLength);
    error NO_PAYEES();
    error NO_AVAILABLE_INCOME();
    error SHARE_CANNOT_BE_ZERO();
    error DEPRECATION_MODE_ENABLED();
    error DEPRECATION_MODE_ALREADY_INITIALIZED();
    error DEPRECATION_MODE_NOT_INITIALIZED();
    error DEPRECATION_MODE_NOT_ENABLED();
    error ELAPSED_TIME_SINCE_DEPRECATION_MODE_INITIALIZATION_TOO_SHORT(uint256 elapsed, uint256 minElapsedTime);
    error AMOUNT_CANNOT_BE_ZERO();
    error BOND_RESERVE_NOT_EMPTY();
    error BUYER_CANNOT_BE_ADDRESS_ZERO();
    error RISK_CATEGORY_MISMATCH();
    error EXPIRED_BONDS_MUST_BE_BOUGHT_FIRST();
    error BOND_NOT_MATURED();
    error CANNOT_TRANSFER_TO_SELF();
    error BOND_ALREADY_EXPIRED();
    error ORACLE_ANSWER_IS_STALE();
}

library MCAG_ERRORS {
    error CANNOT_SET_TO_ADDRESS_ZERO();
    error ERC721_APPROVAL_TO_CURRENT_OWNER();
    error ERC721_APPROVE_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED_FOR_ALL();
    error ERC721_INVALID_TOKEN_ID();
    error ERC721_CALLER_IS_NOT_TOKEN_OWNER();
    error ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(address account, bytes32 role);
    error BLACKLIST_CALLER_IS_NOT_BLACKLISTER();
    error BLACKLIST_ACCOUNT_IS_NOT_BLACKLISTED(address account);
    error BLACKLIST_ACCOUNT_IS_BLACKLISTED(address account);
    error TRANSMITTED_ANSWER_TOO_HIGH(int256 answer, int256 maxAnswer);
    error TRANSMITTED_ANSWER_TOO_LOW(int256 answer, int256 minAnswer);
    error TOKEN_IS_NOT_TRANSFERABLE();
    error KYC_DATA_OWNER_MISMATCH(address to, address owner);
    error RATE_TOO_VOLATILE(uint256 absoluteRateChange, uint256 volatilityThreshold);
    error INVALID_VOLATILITY_THRESHOLD();
    error TERMS_AND_CONDITIONS_URL_DOES_NOT_EXIST(uint256 tncId);
    error TERM_TOO_LOW(uint256 term, uint256 minTerm);
    error RISK_CATEGORY_MISMATCH(bytes4 currency, bytes4 country, uint64 term, bytes32 riskCategory);
    error MATURITY_LESS_THAN_ISSUANCE(uint64 maturity, uint64 issuance);
    error INVALID_RISK_CATEGORY();
    error EMPTY_CUSIP_AND_ISIN();
    error INVALID_MAX_COUPON();
    error INVALID_COUPON(uint256 coupon, uint256 minCoupon, uint256 maxCoupon);
}

/**
 * @title Wrapped Rebase Token Errors library
 *     @author MIMO
 *     @notice Defines the error messages emtted by the wrapped rebase token contract
 */
library WrappedRebaseTokenErrors {
    error CONSTRUCTOR_ARGUMENT_CANNOT_BE_ADDRESS_ZERO();
    error UNWRAP_AMOUNT_EXCEEDS_BALANCE();
    error REBASE_TOKEN_PRICE_INVALID();
    error NO_TOKENS_TO_UNWRAP();
    error CANNOT_WITHDRAW_ZERO_TOKENS();
    error CANNOT_DEPOSIT_ZERO_TOKENS();
}

/**
 * @title Oracle Errors library
 *     @author MIMO
 *     @notice Defines the error messages eimtted by the oracles used by the MIMO protocol
 */
library OracleErrors {
    error CANNOT_SET_TO_ADDRESS_ZERO();
    error CANNOT_SET_TO_EMPTY_STRING();
    error ORACLE_DATA_CANNOT_BE_LESS_THAN_ZERO();
}