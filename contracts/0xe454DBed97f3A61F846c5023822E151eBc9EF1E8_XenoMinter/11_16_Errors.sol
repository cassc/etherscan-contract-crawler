// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @dev Xeno Mining - Error definition contract
 */
contract Errors {
    error InvalidInput(string errMsg);
    string constant INVALID_WITHDRAWAL = "Invalid Withdrawal contract";
    string constant INVALID_MANAGER = "Invalid Manager contract";
    string constant INVALID_SIGNER = "Invalid signer address";
    string constant INVALID_MINTER = "Invalid Minter contract";
    string constant INVALID_SIGNATURE = "Invalid signature";
    string constant INVALID_CURRENCY = "Invalid currency";
    string constant INVALID_ADDRESS = "Invalid wallet address";
    string constant INVALID_AMOUNT = "Invalid amount";

    error UpgradeError(string errMsg);
    string constant WRONG_XENO_CONTRACT = "Wrong Xeno contract";
    string constant WRONG_COUPON_CLIPPER_CONTRACT = "Wrong Coupon Clipper contract";

    error AccessError(string errMsg);
    string constant WRONG_TOKEN_ID = "Wrong token ID";
    string constant WRONG_TOKEN_OWNER = "Wrong token owner";
    string constant WRONG_HASH = "Wrong hash";
    string constant NOT_ASSIGNED = "Address not assigned";

    error PaymentError(string errMsg, uint256 requiredAmount, uint256 receivedAmount);
    string constant INSUFFICIENT_FUNDS = "Insufficient funds";
    string constant NO_PAYMENT_RECEIVED = "No payment received";
    string constant NO_PAYMENT_RECOGNIZED = "MintType/Currency not recognized";
    string constant CURRENCY_DOES_NOT_SUIT_TYPE = "Currency doesn't suit type";
    string constant MINT_TYPE_IS_NOT_SUPPORTED = "MintType isn't supported";

    error MintingError(string errMsg);
    string constant MINTING_DISABLED = "Minting disabled";
    string constant COUNT_TOO_LOW = "Count must be greater than 0";
    string constant TOTAL_SUPPLY_EXCEEDED = "Total supply exceeded";
    string constant PRESALE_SUPPLY_EXCEEDED = "Presale supply exceeded";
    string constant ALLOW_LIST_COUPON_INVALID = "Allow list coupon invalid";
    string constant INVALID_MINTER_ADDRESS = "Minter address invalid";

    error ManagementError(string errMsg);
    string constant CANT_SEND = "Failed to send Ether";
    string constant CANT_REMOVE_SENDER = "Can't remove sender";

    error CouponVerification(string errMsg, address errAddress);
    error CouponValidation(string errMsg);
    string constant INVALID_SIGNER_ADDRESS = "Invalid coupon signer address";
    string constant EXPIRED_COUPON = "Coupon has expired";
    string constant COUNT_LIMIT_REACHED = "Coupon limit reached";
}