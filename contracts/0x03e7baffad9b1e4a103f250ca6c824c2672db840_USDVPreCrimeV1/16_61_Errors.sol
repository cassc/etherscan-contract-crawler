// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library Errors {
    // Invalid Argument (http: 400)
    string internal constant INVALID_ARGUMENT = "LZ10000";
    string internal constant ONLY_REGISTERED = "LZ10001";
    string internal constant ONLY_REGISTERED_OR_DEFAULT = "LZ10002";
    string internal constant INVALID_AMOUNT = "LZ10003";
    string internal constant INVALID_NONCE = "LZ10004";
    string internal constant SAME_VALUE = "LZ10005";
    string internal constant UNSORTED = "LZ10006";
    string internal constant INVALID_VERSION = "LZ10007";
    string internal constant INVALID_EID = "LZ10008";
    string internal constant INVALID_SIZE = "LZ10009";
    string internal constant ONLY_NON_DEFAULT = "LZ10010";
    string internal constant INVALID_VERIFIERS = "LZ10011";
    string internal constant INVALID_WORKER_ID = "LZ10012";
    string internal constant DUPLICATED_OPTION = "LZ10013";
    string internal constant INVALID_LEGACY_OPTION = "LZ10014";
    string internal constant INVALID_VERIFIER_OPTION = "LZ10015";
    string internal constant INVALID_WORKER_OPTIONS = "LZ10016";
    string internal constant INVALID_EXECUTOR_OPTION = "LZ10017";
    string internal constant INVALID_ADDRESS = "LZ10018";

    // Out of Range (http: 400)
    string internal constant OUT_OF_RANGE = "LZ20000";

    // Invalid State (http: 400)
    string internal constant INVALID_STATE = "LZ30000";
    string internal constant SEND_REENTRANCY = "LZ30001";
    string internal constant RECEIVE_REENTRANCY = "LZ30002";
    string internal constant COMPOSE_REENTRANCY = "LZ30003";

    // Permission Denied (http: 403)
    string internal constant PERMISSION_DENIED = "LZ50000";

    // Not Found (http: 404)
    string internal constant NOT_FOUND = "LZ60000";

    // Already Exists (http: 409)
    string internal constant ALREADY_EXISTS = "LZ80000";

    // Not Implemented (http: 501)
    string internal constant NOT_IMPLEMENTED = "LZC0000";
    string internal constant UNSUPPORTED_INTERFACE = "LZC0001";
    string internal constant UNSUPPORTED_OPTION_TYPE = "LZC0002";

    // Unavailable (http: 503)
    string internal constant UNAVAILABLE = "LZD0000";
    string internal constant NATIVE_COIN_UNAVAILABLE = "LZD0001";
    string internal constant TOKEN_UNAVAILABLE = "LZD0002";
    string internal constant DEFAULT_LIBRARY_UNAVAILABLE = "LZD0003";
    string internal constant VERIFIERS_UNAVAILABLE = "LZD0004";
}