// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

library Errors {
    // ViaRouter

    string internal constant INSUFFICIENT_COLLECTED_FEES = "ICF";

    string internal constant EMPTY_EXECUTION = "EE";

    string internal constant DEADLINE_HAS_PASSED = "DHP";

    string internal constant DOUBLE_EXECUTION = "DE";

    string internal constant NOT_SIGNED_BY_VALIDATOR = "NSV";

    string internal constant NOT_AN_ADAPTER = "NAA";

    string internal constant INVALID_SPLIT = "ISP";

    // Transfers

    string internal constant INVALID_MESSAGE_VALUE = "IMV";

    string internal constant INVALID_RECEIVED_AMOUNT = "IRA";

    // Adapters

    string internal constant INVALID_INCOMING_TOKEN = "IIT";

    // Gasless Relay

    string internal constant INVALID_SIGNATURE = "IVS";

    string internal constant NONCE_ALREADY_USED = "NAU";

    string internal constant INVALID_ROUTER_SELECTOR = "IRS";

    string internal constant INVALID_PERMIT_SELECTOR = "IPS";

    // Generic

    string internal constant ZERO_ADDRESS = "ZA";

    string internal constant INVALID_TARGET = "IVT";

    string internal constant LENGHTS_MISMATCH = "LMM";
}