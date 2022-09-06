// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title OpThisAddress
/// @notice Opcode for getting the address of the current contract.
library OpThisAddress {
    function thisAddress(uint256, uint256 stackTopLocation_)
        internal
        view
        returns (uint256)
    {
        assembly {
            mstore(stackTopLocation_, address())
            stackTopLocation_ := add(stackTopLocation_, 0x20)
        }
        return stackTopLocation_;
    }
}