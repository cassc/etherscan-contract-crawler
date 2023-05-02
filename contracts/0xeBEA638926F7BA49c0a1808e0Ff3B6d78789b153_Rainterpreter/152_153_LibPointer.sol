// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

type Pointer is uint256;

library LibPointer {
    function asBytes(Pointer pointer_) internal pure returns (bytes memory bytes_) {
        assembly ("memory-safe") {
            bytes_ := pointer_
        }
    }

    function addBytes(Pointer pointer_, uint256 bytes_) internal pure returns (Pointer) {
        unchecked {
            return Pointer.wrap(Pointer.unwrap(pointer_) + bytes_);
        }
    }

    function addWords(Pointer pointer_, uint256 words_) internal pure returns (Pointer) {
        unchecked {
            return Pointer.wrap(Pointer.unwrap(pointer_) + (words_ * 0x20));
        }
    }

    function allocatedMemoryPointer() internal pure returns (Pointer pointer_) {
        assembly ("memory-safe") {
            pointer_ := mload(0x40)
        }
    }
}