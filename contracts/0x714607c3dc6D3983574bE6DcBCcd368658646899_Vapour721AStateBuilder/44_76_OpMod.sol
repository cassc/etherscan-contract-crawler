// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title OpMod
/// @notice Opcode to mod N numbers.
library OpMod {
    function mod(uint256 operand_, uint256 stackTopLocation_)
        internal
        pure
        returns (uint256)
    {
        assembly {
            let location_ := sub(stackTopLocation_, mul(operand_, 0x20))
            let accumulator_ := mload(location_)
            let item_
            for {
                let cursor_ := add(location_, 0x20)
            } lt(cursor_, stackTopLocation_) {
                cursor_ := add(cursor_, 0x20)
            } {
                item_ := mload(cursor_)
                // Adapted from Open Zeppelin safe math.
                if iszero(item_) {
                    revert(0, 0)
                }
                accumulator_ := mod(accumulator_, item_)
            }
            mstore(location_, accumulator_)
            stackTopLocation_ := add(location_, 0x20)
        }

        return stackTopLocation_;
    }
}