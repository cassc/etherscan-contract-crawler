// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title OpBlockNumber
/// @notice Opcode for getting the current block number.
library OpBlockNumber {
    function blockNumber(uint256, uint256 stackTopLocation_)
        internal
        view
        returns (uint256)
    {
        assembly {
            mstore(stackTopLocation_, number())
            stackTopLocation_ := add(stackTopLocation_, 0x20)
        }
        return stackTopLocation_;
    }
}