// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @dev ASM The Next Legends - Error definition contract
 */
contract Errors {
    error InvalidInput(string errMsg);
    string constant INVALID_MULTISIG = "Invalid Multisig contract";
    string constant INVALID_MANAGER = "Invalid Manager contract";
    string constant INVALID_SIGNER = "Invalid signer address";
    string constant INVALID_MINTER = "Invalid Minter contract";
    string constant INVALID_SIGNATURE = "Invalid signature";
    string constant INVALID_CURRENCY = "Invalid currency";
    string constant INVALID_ADDRESS = "Invalid wallet address";
    string constant INVALID_AMOUNT = "Invalid amount";

    error UpgradeError(string errMsg);
    string constant WRONG_CHARACTER_CONTRACT = "Wrong character contract";
    string constant WRONG_BAG_CONTRACT = "Wrong bag contract";
    string constant WRONG_UNPACKER_CONTRACT = "Wrong unpacker contract";
    string constant WRONG_MINTER_CONTRACT = "Wrong minter contract";
    string constant WRONG_ASSET_CONTRACT = "Wrong asset contract";
    string constant WRONG_PAYMENT_CONTRACT = "Wrong payment contract";
    string constant WRONG_ASTO_CONTRACT = "Wrong ASTO contract";
    string constant WRONG_LP_CONTRACT = "Wrong LP contract";

    error AccessError(string errMsg);
    string constant WRONG_TOKEN_ID = "Wrong token ID";
    string constant WRONG_TOKEN_OWNER = "Wrong token owner";
    string constant WRONG_HASH = "Wrong hash";
    string constant NOT_ASSIGNED = "Address not assigned";

    error PaymentError(string errMsg, uint256 requiredAmount, uint256 receivedAmount);
    string constant INSUFFICIENT_BALANCE = "Insufficient balance";
    string constant NO_PAYMENT_RECEIVED = "No payment received";
    string constant NO_PAYMENT_RECOGNIZED = "MintType/Currency not recognized";
    string constant CURRENCY_DOES_NOT_SUIT_TYPE = "Currency doesn't suit type";
    string constant MINT_TYPE_IS_NOT_SUPPORTED = "MintType isn't supported";

    error MintingError(string errMsg, uint256 expiry);
    error OpenError(string errMsg);
    string constant MINT_EXPIRED = "Mint hash has expired";
    string constant TOKEN_ALREADY_MINTED = "Token has already minted";
    string constant NOT_ALLOWED = "Currently is not allowed";
    string constant TOTAL_SUPPLY_EXCEEDED = "Total supply exceeded";

    error ManagementError(string errMsg);
    string constant CANT_SEND = "Failed to send Ether";
}