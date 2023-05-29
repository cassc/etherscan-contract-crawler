// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '../interface/Constants.sol';

library PackedByteUtility {
    /**
     * @notice get the byte value of a right-indexed byte within a uint256
     * @param  index right-indexed location of byte within uint256
     * @param  packedBytes uint256 of bytes
     * @return result the byte at right-indexed index within packedBytes
     */
    function getPackedByteFromRight(uint256 packedBytes, uint256 index)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := byte(sub(31, index), packedBytes)
        }
    }

    /**
     * @notice get the byte value of a left-indexed byte within a uint256
     * @param  index left-indexed location of byte within uint256
     * @param  packedBytes uint256 of bytes
     * @return result the byte at left-indexed index within packedBytes
     */
    function getPackedByteFromLeft(uint256 packedBytes, uint256 index)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := byte(index, packedBytes)
        }
    }

    function packShortAtIndex(
        uint256 packedShorts,
        uint256 shortToPack,
        uint256 index
    ) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let shortOffset := sub(240, shl(4, index))
            let mask := xor(MAX_INT, shl(shortOffset, 0xffff))
            result := and(packedShorts, mask)
            result := or(result, shl(shortOffset, shortToPack))
        }
    }

    function getPackedShortFromRight(uint256 packed, uint256 index)
        internal
        pure
        returns (uint256 result)
    {
        assembly {
            let shortOffset := shl(4, index)
            result := shr(shortOffset, packed)
            result := and(result, 0xffff)
        }
    }

    function getPackedNFromRight(
        uint256 packed,
        uint256 bitsPerIndex,
        uint256 index
    ) internal pure returns (uint256 result) {
        assembly {
            let offset := mul(bitsPerIndex, index)
            let mask := sub(shl(bitsPerIndex, 1), 1)
            result := shr(offset, packed)
            result := and(result, mask)
        }
    }

    function packNAtRightIndex(
        uint256 packed,
        uint256 bitsPerIndex,
        uint256 toPack,
        uint256 index
    ) internal pure returns (uint256 result) {
        assembly {
            // left-shift offset
            let offset := mul(bitsPerIndex, index)
            // mask for 2**n uint
            let nMask := sub(shl(bitsPerIndex, 1), 1)
            // mask to clear bits at offset
            let mask := xor(MAX_INT, shl(offset, nMask))
            // clear bits at offset
            result := and(packed, mask)
            // shift toPack to offset, then pack
            result := or(result, shl(offset, toPack))
        }
    }

    function getPackedShortFromLeft(uint256 packed, uint256 index)
        internal
        pure
        returns (uint256 result)
    {
        assembly {
            let shortOffset := sub(240, shl(4, index))
            result := shr(shortOffset, packed)
            result := and(result, 0xffff)
        }
    }

    /**
     * @notice unpack elements of a packed byte array into a bitmap. Short-circuits at first 0-byte.
     * @param  packedBytes uint256 of bytes
     * @return unpacked - 1-indexed bitMap of all byte values contained in packedBytes up until the first 0-byte
     */
    function unpackBytesToBitMap(uint256 packedBytes)
        internal
        pure
        returns (uint256 unpacked)
    {
        /// @solidity memory-safe-assembly
        assembly {
            for {
                let i := 0
            } lt(i, 32) {
                i := add(i, 1)
            } {
                // this is the ID of the layer, eg, 1, 5, 253
                let byteVal := byte(i, packedBytes)
                // don't count zero bytes
                if iszero(byteVal) {
                    break
                }
                // byteVals are 1-indexed because we're shifting 1 by the value of the byte
                unpacked := or(unpacked, shl(byteVal, 1))
            }
        }
    }

    /**
     * @notice pack byte values into a uint256. Note: *will not* short-circuit on first 0-byte
     * @param  arrayOfBytes uint256[] of byte values
     * @return packed uint256 of packed bytes
     */
    function packArrayOfBytes(uint256[] memory arrayOfBytes)
        internal
        pure
        returns (uint256 packed)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let arrayOfBytesIndexPtr := add(arrayOfBytes, 0x20)
            let arrayOfBytesLength := mload(arrayOfBytes)
            if gt(arrayOfBytesLength, 32) {
                arrayOfBytesLength := 32
            }
            let finalI := shl(3, arrayOfBytesLength)
            let i
            for {

            } lt(i, finalI) {
                arrayOfBytesIndexPtr := add(0x20, arrayOfBytesIndexPtr)
                i := add(8, i)
            } {
                packed := or(
                    packed,
                    shl(sub(248, i), mload(arrayOfBytesIndexPtr))
                )
            }
        }
    }

    function packArrayOfShorts(uint256[] memory shorts)
        internal
        pure
        returns (uint256[2] memory packed)
    {
        packed = [uint256(0), uint256(0)];
        for (uint256 i; i < shorts.length; i++) {
            if (i == 32) {
                break;
            }
            uint256 j = i / 16;
            uint256 index = i % 16;
            packed[j] = packShortAtIndex(packed[j], shorts[i], index);
        }
    }

    /**
     * @notice Unpack a packed uint256 of bytes into a uint256 array of byte values. Short-circuits on first 0-byte.
     * @param  packedByteArray The packed uint256 of bytes to unpack
     * @return unpacked uint256[] The unpacked uint256 array of bytes
     */
    function unpackByteArray(uint256 packedByteArray)
        internal
        pure
        returns (uint256[] memory unpacked)
    {
        /// @solidity memory-safe-assembly
        assembly {
            unpacked := mload(0x40)
            let unpackedIndexPtr := add(0x20, unpacked)
            let maxUnpackedIndexPtr := add(unpackedIndexPtr, shl(5, 32))
            let numBytes
            for {

            } lt(unpackedIndexPtr, maxUnpackedIndexPtr) {
                unpackedIndexPtr := add(0x20, unpackedIndexPtr)
                numBytes := add(1, numBytes)
            } {
                let byteVal := byte(numBytes, packedByteArray)
                if iszero(byteVal) {
                    break
                }
                mstore(unpackedIndexPtr, byteVal)
            }
            // store the number of layers at the pointer to unpacked array
            mstore(unpacked, numBytes)
            // update free mem pointer to be old mem ptr + 0x20 (32-byte array length) + 0x20 * numLayers (each 32-byte element)
            mstore(0x40, add(unpacked, add(0x20, shl(5, numBytes))))
        }
    }

    /**
     * @notice given a uint256 packed array of bytes, pack a byte at an index from the left
     * @param packedBytes existing packed bytes
     * @param byteToPack byte to pack into packedBytes
     * @param index index to pack byte at
     * @return newPackedBytes with byteToPack at index
     */
    function packByteAtIndex(
        uint256 packedBytes,
        uint256 byteToPack,
        uint256 index
    ) internal pure returns (uint256 newPackedBytes) {
        /// @solidity memory-safe-assembly
        assembly {
            // calculate left-indexed bit offset of byte within packedBytes
            let byteOffset := sub(248, shl(3, index))
            // create a mask to clear the bits we're about to overwrite
            let mask := xor(MAX_INT, shl(byteOffset, 0xff))
            // copy packedBytes to newPackedBytes, clearing the relevant bits
            newPackedBytes := and(packedBytes, mask)
            // shift the byte to the offset and OR it into newPackedBytes
            newPackedBytes := or(newPackedBytes, shl(byteOffset, byteToPack))
        }
    }

    /// @dev less efficient logic for packing >32 bytes into >1 uint256
    function packArraysOfBytes(uint256[] memory arrayOfBytes)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 arrayOfBytesLength = arrayOfBytes.length;
        uint256[] memory packed = new uint256[](
            (arrayOfBytesLength - 1) / 32 + 1
        );
        uint256 workingWord = 0;
        for (uint256 i = 0; i < arrayOfBytesLength; ) {
            // OR workingWord with this byte shifted by byte within the word
            workingWord |= uint256(arrayOfBytes[i]) << (8 * (31 - (i % 32)));

            // if we're on the last byte of the word, store in array
            if (i % 32 == 31) {
                uint256 j = i / 32;
                packed[j] = workingWord;
                workingWord = 0;
            }
            unchecked {
                ++i;
            }
        }
        if (arrayOfBytesLength % 32 != 0) {
            packed[packed.length - 1] = workingWord;
        }

        return packed;
    }

    /// @dev less efficient logic for unpacking >1 uint256s into >32 byte values
    function unpackByteArrays(uint256[] memory packedByteArrays)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256 packedByteArraysLength = packedByteArrays.length;
        uint256[] memory unpacked = new uint256[](packedByteArraysLength * 32);
        for (uint256 i = 0; i < packedByteArraysLength; ) {
            uint256 packedByteArray = packedByteArrays[i];
            uint256 j = 0;
            for (; j < 32; ) {
                uint256 unpackedByte = getPackedByteFromLeft(
                    j,
                    packedByteArray
                );
                if (unpackedByte == 0) {
                    break;
                }
                unpacked[i * 32 + j] = unpackedByte;
                unchecked {
                    ++j;
                }
            }
            if (j < 32) {
                break;
            }
            unchecked {
                ++i;
            }
        }
        return unpacked;
    }
}