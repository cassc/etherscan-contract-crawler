// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title OpTimestamp
/// @notice Opcode for getting the current timestamp.
library OpTimestamp {
    function timestamp(uint256, uint256 stackTopLocation_)
        internal
        view
        returns (uint256)
    {
        assembly {
            mstore(stackTopLocation_, timestamp())
            stackTopLocation_ := add(stackTopLocation_, 0x20)
        }
        return stackTopLocation_;
    }
}