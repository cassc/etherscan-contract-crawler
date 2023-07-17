// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./LibPointer.sol";

/// Thrown when asked to truncate data to a longer length.
/// @param length Actual bytes length.
/// @param truncate Attempted truncation length.
error TruncateError(uint256 length, uint256 truncate);

/// @title LibBytes
/// @notice Tools for working directly with memory in a Solidity compatible way.
library LibBytes {
    /// Truncates bytes of data by mutating its length directly.
    /// Any excess bytes are leaked
    function truncate(bytes memory data, uint256 length) internal pure {
        if (data.length < length) {
            revert TruncateError(data.length, length);
        }
        assembly ("memory-safe") {
            mstore(data, length)
        }
    }

    /// Pointer to the data of a bytes array NOT the length prefix.
    /// @param data Bytes to get the data pointer for.
    /// @return pointer Pointer to the data of the bytes in memory.
    function dataPointer(bytes memory data) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(data, 0x20)
        }
    }

    /// Pointer to the start of a bytes array (the length prefix).
    /// @param data Bytes to get the pointer to.
    /// @return pointer Pointer to the start of the bytes data structure.
    function startPointer(bytes memory data) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := data
        }
    }

    /// Pointer to the end of some bytes.
    ///
    /// Note that this pointer MAY NOT BE ALIGNED, i.e. it MAY NOT point to the
    /// start of a multiple of 32, UNLIKE the free memory pointer at 0x40.
    ///
    /// @param data Bytes to get the pointer to the end of.
    /// @return pointer Pointer to the end of the bytes data structure.
    function endDataPointer(bytes memory data) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(data, add(0x20, mload(data)))
        }
    }

    /// Pointer to the end of the memory allocated for bytes.
    ///
    /// The allocator is ALWAYS aligned to whole words, i.e. 32 byte multiples,
    /// for data structures allocated by Solidity. This includes `bytes` which
    /// means that any time the length of some `bytes` is NOT a multiple of 32
    /// the alloation will point past the end of the `bytes` data.
    ///
    /// There is no guarantee that the memory region between `endDataPointer`
    /// and `endAllocatedPointer` is zeroed out. It is best to think of that
    /// space as leaked garbage.
    ///
    /// Almost always, e.g. for the purpose of copying data between regions, you
    /// will want `endDataPointer` rather than this function.
    /// @param data Bytes to get the end of the allocated data region for.
    /// @return pointer Pointer to the end of the allocated data region.
    function endAllocatedPointer(bytes memory data) internal pure returns (Pointer pointer) {
        assembly ("memory-safe") {
            pointer := add(data, and(add(add(mload(data), 0x20), 0x1f), not(0x1f)))
        }
    }
}