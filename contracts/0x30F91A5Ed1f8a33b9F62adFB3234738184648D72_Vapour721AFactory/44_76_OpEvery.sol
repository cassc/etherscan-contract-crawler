// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title OpEvery
/// @notice Opcode to compare the top N stack values.
library OpEvery {
    // EVERY
    // EVERY is either the first item if every item is nonzero, else 0.
    // operand_ is the length of items to check.
    function every(uint256 operand_, uint256 stackTopLocation_)
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
                // If anything is zero then EVERY is a failed check.
                if iszero(mload(cursor_)) {
                    mstore(location_, 0)
                    break
                }
            }
            stackTopLocation_ := add(location_, 0x20)
        }
        return stackTopLocation_;
    }
}