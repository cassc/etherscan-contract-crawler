// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title OpGreaterThan
/// @notice Opcode to compare the top two stack values.
library OpGreaterThan {
    function greaterThan(uint256, uint256 stackTopLocation_)
        internal
        pure
        returns (uint256)
    {
        assembly {
            stackTopLocation_ := sub(stackTopLocation_, 0x20)
            let location_ := sub(stackTopLocation_, 0x20)
            mstore(location_, gt(mload(location_), mload(stackTopLocation_)))
        }
        return stackTopLocation_;
    }
}