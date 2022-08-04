// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title OpAny
/// @notice Opcode to compare the top N stack values.
library OpAny {
    // ANY
    // ANY is the first nonzero item, else 0.
    // operand_ id the length of items to check.
    function any(uint256 operand_, uint256 stackTopLocation_)
        internal
        pure
        returns (uint256)
    {
        assembly {
            let location_ := sub(stackTopLocation_, mul(operand_, 0x20))
            for {
                let cursor_ := location_
            } lt(cursor_, stackTopLocation_) {
                cursor_ := add(cursor_, 0x20)
            } {
                // If anything is NOT zero then ANY is a successful
                // check and can short-circuit.
                let item_ := mload(cursor_)
                if iszero(iszero(item_)) {
                    // Write the usable value to the top of the stack.
                    mstore(location_, item_)
                    break
                }
            }
            stackTopLocation_ := add(location_, 0x20)
        }
        return stackTopLocation_;
    }
}