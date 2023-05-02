// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

library LibMemory {
    function memoryIsAligned() internal pure returns (bool isAligned_) {
        assembly ("memory-safe") {
            isAligned_ := iszero(mod(mload(0x40), 0x20))
        }
    }
}