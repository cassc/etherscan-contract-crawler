// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Errors {
    string internal constant ADDRESS_0_PROVIDED = "ADDRESS_0_PROVIDED";
    string internal constant DEX_NOT_ALLOWED = "DEX_NOT_ALLOWED";
    string internal constant TOKEN_NOT_SUPPORTED = "TOKEN_NOT_SUPPORTED";
    string internal constant SWAP_FAILED = "SWAP_FAILED";
    string internal constant VALUE_SHOULD_BE_ZERO = "VALUE_SHOULD_BE_ZERO";
    string internal constant VALUE_SHOULD_NOT_BE_ZERO = "VALUE_SHOULD_NOT_BE_ZERO";
    string internal constant VALUE_NOT_EQUAL_TO_AMOUNT = "VALUE_NOT_EQUAL_TO_AMOUNT";

    string internal constant INVALID_AMT = "INVALID_AMT";
    string internal constant INVALID_ADDRESS = "INVALID_ADDRESS";
    string internal constant INVALID_SENDER = "INVALID_SENDER";

    string internal constant UNKNOWN_TRANSFER_ID = "UNKNOWN_TRANSFER_ID";
    string internal constant CALL_DATA_MUST_SIGNED_BY_OWNER = "CALL_DATA_MUST_SIGNED_BY_OWNER";

}