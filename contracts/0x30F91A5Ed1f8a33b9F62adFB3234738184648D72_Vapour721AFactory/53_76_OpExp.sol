// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title OpExp
/// @notice Opcode to exponentiate N numbers.
library OpExp {
    function exp(uint256 operand_, uint256 stackTopLocation_)
        internal
        pure
        returns (uint256)
    {
        uint256 location_;
        uint256 accumulator_;
        uint256 cursor_;
        uint256 item_;
        assembly {
            location_ := sub(stackTopLocation_, mul(operand_, 0x20))
            accumulator_ := mload(location_)
            cursor_ := add(location_, 0x20)
        }
        while (cursor_ < stackTopLocation_) {
            assembly {
                item_ := mload(cursor_)
                cursor_ := add(cursor_, 0x20)
            }
            // This is NOT in assembly so that we get overflow safety.
            accumulator_ = accumulator_**item_;
        }
        assembly {
            mstore(location_, accumulator_)
            stackTopLocation_ := add(location_, 0x20)
        }
        return stackTopLocation_;
    }
}