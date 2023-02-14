// SPDX-License-Identifier: -
// License: https://license.clober.io/LICENSE.pdf

pragma solidity ^0.8.0;

library Errors {
    error CloberError(uint256 errorCode); // 0x1d25260a

    uint256 public constant ACCESS = 0;
    uint256 public constant FAILED_TO_SEND_VALUE = 1;
    uint256 public constant INSUFFICIENT_BALANCE = 2;
    uint256 public constant OVERFLOW_UNDERFLOW = 3;
    uint256 public constant EMPTY_INPUT = 4;
    uint256 public constant DELEGATE_CALL = 5;
    uint256 public constant DEADLINE = 6;
    uint256 public constant NOT_IMPLEMENTED_INTERFACE = 7;
    uint256 public constant INVALID_FEE = 8;
    uint256 public constant REENTRANCY = 9;
    uint256 public constant POST_ONLY = 10;
    uint256 public constant SLIPPAGE = 11;
    uint256 public constant QUEUE_REPLACE_FAILED = 12;
    uint256 public constant INVALID_COEFFICIENTS = 13;
    uint256 public constant INVALID_ID = 14;
    uint256 public constant INVALID_QUOTE_TOKEN = 15;
    uint256 public constant INVALID_PRICE = 16;
}