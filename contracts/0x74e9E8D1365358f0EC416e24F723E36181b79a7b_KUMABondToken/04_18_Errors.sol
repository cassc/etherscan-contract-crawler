// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Errors {
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
    error RISK_CATEGORY_MISMATCH(bytes4 currency, bytes32 name, uint64 term, bytes32 riskCategory);
    error MATURITY_LESS_THAN_ISSUANCE(uint64 maturity, uint64 issuance);
    error INVALID_RISK_CATEGORY();
    error EMPTY_CUSIP_AND_ISIN();
    error INVALID_MAX_COUPON();
    error INVALID_COUPON(uint256 coupon, uint256 minCoupon, uint256 maxCoupon);
}