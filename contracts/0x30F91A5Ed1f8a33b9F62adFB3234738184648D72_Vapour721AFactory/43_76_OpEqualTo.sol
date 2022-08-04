// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title OpEqualTo
/// @notice Opcode to compare the top two stack values.
library OpEqualTo {
    function equalTo(uint256, uint256 stackTopLocation_)
        internal
        pure
        returns (uint256)
    {
        assembly {
            stackTopLocation_ := sub(stackTopLocation_, 0x20)
            let location_ := sub(stackTopLocation_, 0x20)
            mstore(location_, eq(mload(location_), mload(stackTopLocation_)))
        }
        return stackTopLocation_;
    }
}