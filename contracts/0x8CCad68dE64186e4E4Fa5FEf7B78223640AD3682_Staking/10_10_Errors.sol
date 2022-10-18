// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library Errors {
    string internal constant ZERO_VALIDATOR = "ZV";

    string internal constant LENGHTS_MISMATCH = "LM";

    string internal constant INVALID_NODE = "IN";

    string internal constant NOT_STAKE_OWNER = "NSO";

    string internal constant NOT_NODE_VALIDATOR = "NND";

    string internal constant NOT_OWNER_OR_VALIDATOR = "NOV";

    string internal constant NODE_NOT_ACTIVE = "NNA";

    string internal constant FEE_OVERFLOW = "FOF";
}