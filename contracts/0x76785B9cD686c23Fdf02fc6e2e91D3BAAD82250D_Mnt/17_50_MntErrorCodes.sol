// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

library MntErrorCodes {
    string internal constant UNAUTHORIZED = "E102";
    string internal constant TARGET_ADDRESS_CANNOT_BE_ZERO = "E225";
    string internal constant MV_BLOCK_NOT_YET_MINED = "E262";
    string internal constant MV_SIGNATURE_EXPIRED = "E263";
    string internal constant MV_INVALID_NONCE = "E264";
    string internal constant SECOND_INITIALIZATION = "E402";
    string internal constant IDENTICAL_VALUE = "E404";
    string internal constant ZERO_ADDRESS = "E405";
    string internal constant MNT_INVALID_NONVOTING_PERIOD = "E420";
}