// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/BaseParserLibraryErrors.sol";

library BaseParserLibrary {
    // Size of a word, in bytes.
    uint256 internal constant _WORD_SIZE = 32;
    // Size of the header of a 'bytes' array.
    uint256 internal constant _BYTES_HEADER_SIZE = 32;

    /// @notice Extracts a uint32 from a little endian bytes array.
    /// @param src the binary state
    /// @param offset place inside `src` to start reading state from
    /// @return val a uint32
    /// @dev ~559 gas
    function extractUInt32(bytes memory src, uint256 offset) internal pure returns (uint32 val) {
        if (offset + 4 <= offset) {
            revert BaseParserLibraryErrors.OffsetParameterOverflow(offset);
        }

        if (offset + 4 > src.length) {
            revert BaseParserLibraryErrors.OffsetOutOfBounds(offset + 4, src.length);
        }

        assembly ("memory-safe") {
            val := shr(sub(256, 32), mload(add(add(src, 0x20), offset)))
            val := or(
                or(
                    or(shr(24, and(val, 0xff000000)), shr(8, and(val, 0x00ff0000))),
                    shl(8, and(val, 0x0000ff00))
                ),
                shl(24, and(val, 0x000000ff))
            )
        }
    }

    /// @notice Extracts a uint16 from a little endian bytes array.
    /// @param src the binary state
    /// @param offset place inside `src` to start reading state from
    /// @return val a uint16
    /// @dev ~204 gas
    function extractUInt16(bytes memory src, uint256 offset) internal pure returns (uint16 val) {
        if (offset + 2 <= offset) {
            revert BaseParserLibraryErrors.LEUint16OffsetParameterOverflow(offset);
        }

        if (offset + 2 > src.length) {
            revert BaseParserLibraryErrors.LEUint16OffsetOutOfBounds(offset + 2, src.length);
        }

        assembly ("memory-safe") {
            val := shr(sub(256, 16), mload(add(add(src, 0x20), offset)))
            val := or(shr(8, and(val, 0xff00)), shl(8, and(val, 0x00ff)))
        }
    }

    /// @notice Extracts a uint16 from a big endian bytes array.
    /// @param src the binary state
    /// @param offset place inside `src` to start reading state from
    /// @return val a uint16
    /// @dev ~204 gas
    function extractUInt16FromBigEndian(
        bytes memory src,
        uint256 offset
    ) internal pure returns (uint16 val) {
        if (offset + 2 <= offset) {
            revert BaseParserLibraryErrors.BEUint16OffsetParameterOverflow(offset);
        }

        if (offset + 2 > src.length) {
            revert BaseParserLibraryErrors.BEUint16OffsetOutOfBounds(offset + 2, src.length);
        }

        assembly ("memory-safe") {
            val := and(shr(sub(256, 16), mload(add(add(src, 0x20), offset))), 0xffff)
        }
    }

    /// @notice Extracts a bool from a bytes array.
    /// @param src the binary state
    /// @param offset place inside `src` to start reading state from
    /// @return a bool
    /// @dev ~204 gas
    function extractBool(bytes memory src, uint256 offset) internal pure returns (bool) {
        if (offset + 1 <= offset) {
            revert BaseParserLibraryErrors.BooleanOffsetParameterOverflow(offset);
        }

        if (offset + 1 > src.length) {
            revert BaseParserLibraryErrors.BooleanOffsetOutOfBounds(offset + 1, src.length);
        }

        uint256 val;
        assembly ("memory-safe") {
            val := shr(sub(256, 8), mload(add(add(src, 0x20), offset)))
            val := and(val, 0x01)
        }
        return val == 1;
    }

    /// @notice Extracts a uint256 from a little endian bytes array.
    /// @param src the binary state
    /// @param offset place inside `src` to start reading state from
    /// @return val a uint256
    /// @dev ~5155 gas
    function extractUInt256(bytes memory src, uint256 offset) internal pure returns (uint256 val) {
        if (offset + 32 <= offset) {
            revert BaseParserLibraryErrors.LEUint256OffsetParameterOverflow(offset);
        }

        if (offset + 32 > src.length) {
            revert BaseParserLibraryErrors.LEUint256OffsetOutOfBounds(offset + 32, src.length);
        }

        assembly ("memory-safe") {
            val := mload(add(add(src, 0x20), offset))
        }
    }

    /// @notice Extracts a uint256 from a big endian bytes array.
    /// @param src the binary state
    /// @param offset place inside `src` to start reading state from
    /// @return val a uint256
    /// @dev ~1400 gas
    function extractUInt256FromBigEndian(
        bytes memory src,
        uint256 offset
    ) internal pure returns (uint256 val) {
        if (offset + 32 <= offset) {
            revert BaseParserLibraryErrors.BEUint256OffsetParameterOverflow(offset);
        }

        if (offset + 32 > src.length) {
            revert BaseParserLibraryErrors.BEUint256OffsetOutOfBounds(offset + 32, src.length);
        }

        uint256 srcDataPointer;
        uint32 val0 = 0;
        uint32 val1 = 0;
        uint32 val2 = 0;
        uint32 val3 = 0;
        uint32 val4 = 0;
        uint32 val5 = 0;
        uint32 val6 = 0;
        uint32 val7 = 0;

        assembly ("memory-safe") {
            srcDataPointer := mload(add(add(src, 0x20), offset))
            val0 := and(srcDataPointer, 0xffffffff)
            val1 := and(shr(32, srcDataPointer), 0xffffffff)
            val2 := and(shr(64, srcDataPointer), 0xffffffff)
            val3 := and(shr(96, srcDataPointer), 0xffffffff)
            val4 := and(shr(128, srcDataPointer), 0xffffffff)
            val5 := and(shr(160, srcDataPointer), 0xffffffff)
            val6 := and(shr(192, srcDataPointer), 0xffffffff)
            val7 := and(shr(224, srcDataPointer), 0xffffffff)

            val0 := or(
                or(
                    or(shr(24, and(val0, 0xff000000)), shr(8, and(val0, 0x00ff0000))),
                    shl(8, and(val0, 0x0000ff00))
                ),
                shl(24, and(val0, 0x000000ff))
            )
            val1 := or(
                or(
                    or(shr(24, and(val1, 0xff000000)), shr(8, and(val1, 0x00ff0000))),
                    shl(8, and(val1, 0x0000ff00))
                ),
                shl(24, and(val1, 0x000000ff))
            )
            val2 := or(
                or(
                    or(shr(24, and(val2, 0xff000000)), shr(8, and(val2, 0x00ff0000))),
                    shl(8, and(val2, 0x0000ff00))
                ),
                shl(24, and(val2, 0x000000ff))
            )
            val3 := or(
                or(
                    or(shr(24, and(val3, 0xff000000)), shr(8, and(val3, 0x00ff0000))),
                    shl(8, and(val3, 0x0000ff00))
                ),
                shl(24, and(val3, 0x000000ff))
            )
            val4 := or(
                or(
                    or(shr(24, and(val4, 0xff000000)), shr(8, and(val4, 0x00ff0000))),
                    shl(8, and(val4, 0x0000ff00))
                ),
                shl(24, and(val4, 0x000000ff))
            )
            val5 := or(
                or(
                    or(shr(24, and(val5, 0xff000000)), shr(8, and(val5, 0x00ff0000))),
                    shl(8, and(val5, 0x0000ff00))
                ),
                shl(24, and(val5, 0x000000ff))
            )
            val6 := or(
                or(
                    or(shr(24, and(val6, 0xff000000)), shr(8, and(val6, 0x00ff0000))),
                    shl(8, and(val6, 0x0000ff00))
                ),
                shl(24, and(val6, 0x000000ff))
            )
            val7 := or(
                or(
                    or(shr(24, and(val7, 0xff000000)), shr(8, and(val7, 0x00ff0000))),
                    shl(8, and(val7, 0x0000ff00))
                ),
                shl(24, and(val7, 0x000000ff))
            )

            val := or(
                or(
                    or(
                        or(
                            or(
                                or(or(shl(224, val0), shl(192, val1)), shl(160, val2)),
                                shl(128, val3)
                            ),
                            shl(96, val4)
                        ),
                        shl(64, val5)
                    ),
                    shl(32, val6)
                ),
                val7
            )
        }
    }

    /// @notice Reverts a bytes array. Can be used to convert an array from little endian to big endian and vice-versa.
    /// @param orig the binary state
    /// @return reversed the reverted bytes array
    /// @dev ~13832 gas
    function reverse(bytes memory orig) internal pure returns (bytes memory reversed) {
        reversed = new bytes(orig.length);
        for (uint256 idx = 0; idx < orig.length; idx++) {
            reversed[orig.length - idx - 1] = orig[idx];
        }
    }

    /// @notice Copy 'len' bytes from memory address 'src', to address 'dest'. This function does not check the or destination, it only copies the bytes.
    /// @param src the pointer to the source
    /// @param dest the pointer to the destination
    /// @param len the len of state to be copied
    function copy(uint256 src, uint256 dest, uint256 len) internal pure {
        // Copy word-length chunks while possible
        for (; len >= _WORD_SIZE; len -= _WORD_SIZE) {
            assembly ("memory-safe") {
                mstore(dest, mload(src))
            }
            dest += _WORD_SIZE;
            src += _WORD_SIZE;
        }
        // Returning earlier if there's no leftover bytes to copy
        if (len == 0) {
            return;
        }
        // Copy remaining bytes
        uint256 mask = 256 ** (_WORD_SIZE - len) - 1;
        assembly ("memory-safe") {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /// @notice Returns a memory pointer to the state portion of the provided bytes array.
    /// @param bts the bytes array to get a pointer from
    /// @return addr the pointer to the `bts` bytes array
    function dataPtr(bytes memory bts) internal pure returns (uint256 addr) {
        assembly ("memory-safe") {
            addr := add(bts, _BYTES_HEADER_SIZE)
        }
    }

    /// @notice Extracts a bytes array with length `howManyBytes` from `src`'s `offset` forward.
    /// @param src the bytes array to extract from
    /// @param offset where to start extracting from
    /// @param howManyBytes how many bytes we want to extract from `src`
    /// @return out the extracted bytes array
    /// @dev Extracting the 32-64th bytes out of a 64 bytes array takes ~7828 gas.
    function extractBytes(
        bytes memory src,
        uint256 offset,
        uint256 howManyBytes
    ) internal pure returns (bytes memory out) {
        if (offset + howManyBytes < offset) {
            revert BaseParserLibraryErrors.BytesOffsetParameterOverflow(offset);
        }

        if (offset + howManyBytes > src.length) {
            revert BaseParserLibraryErrors.BytesOffsetOutOfBounds(
                offset + howManyBytes,
                src.length
            );
        }

        out = new bytes(howManyBytes);
        uint256 start;

        assembly ("memory-safe") {
            start := add(add(src, offset), _BYTES_HEADER_SIZE)
        }

        copy(start, dataPtr(out), howManyBytes);
    }

    /// @notice Extracts a bytes32 extracted from `src`'s `offset` forward.
    /// @param src the source bytes array to extract from
    /// @param offset where to start extracting from
    /// @return out the bytes32 state extracted from `src`
    /// @dev ~439 gas
    function extractBytes32(bytes memory src, uint256 offset) internal pure returns (bytes32 out) {
        if (offset + 32 <= offset) {
            revert BaseParserLibraryErrors.Bytes32OffsetParameterOverflow(offset);
        }

        if (offset + 32 > src.length) {
            revert BaseParserLibraryErrors.Bytes32OffsetOutOfBounds(offset + 32, src.length);
        }

        assembly ("memory-safe") {
            out := mload(add(add(src, _BYTES_HEADER_SIZE), offset))
        }
    }
}