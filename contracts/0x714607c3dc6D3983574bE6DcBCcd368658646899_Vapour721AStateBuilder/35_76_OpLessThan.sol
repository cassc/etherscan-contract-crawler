// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title OpLessThan
/// @notice Opcode to compare the top two stack values.
library OpLessThan {
    function lessThan(uint256, uint256 stackTopLocation_)
        internal
        pure
        returns (uint256)
    {
        assembly {
            stackTopLocation_ := sub(stackTopLocation_, 0x20)
            let location_ := sub(stackTopLocation_, 0x20)
            mstore(location_, lt(mload(location_), mload(stackTopLocation_)))
        }
        return stackTopLocation_;
    }
}