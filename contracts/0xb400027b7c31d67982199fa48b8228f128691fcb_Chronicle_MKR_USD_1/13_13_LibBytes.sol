// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 * @title LibBytes
 *
 * @notice Library for common byte operations
 */
library LibBytes {
    /// @dev Returns the `index`'s byte from `word`.
    ///
    ///      It is the caller's responsibility to ensure `index < 32`!
    ///
    /// @custom:invariant Uses constant amount of gas.
    function getByteAtIndex(uint word, uint index)
        internal
        pure
        returns (uint)
    {
        uint result;
        assembly ("memory-safe") {
            result := byte(sub(31, index), word)
        }

        // Note that the resulting byte is returned as word.
        return result;
    }
}