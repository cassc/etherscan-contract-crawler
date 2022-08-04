// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title OpCaller
/// @notice Opcode for getting the current caller.
library OpCaller {
    function caller(uint256, uint256 stackTopLocation_)
        internal
        view
        returns (uint256)
    {
        assembly {
            mstore(stackTopLocation_, caller())
            stackTopLocation_ := add(stackTopLocation_, 0x20)
        }
        return stackTopLocation_;
    }
}