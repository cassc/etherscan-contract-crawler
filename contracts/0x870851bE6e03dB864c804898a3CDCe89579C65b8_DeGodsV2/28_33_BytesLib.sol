// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      This is a reduced version of the library.
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    uint256 private constant freeMemoryPtr = 0x40;
    uint256 private constant maskModulo32 = 0x1f;
    /**
     * Size of word read by `mload` instruction.
     */
    uint256 private constant memoryWord = 32;
    uint256 internal constant uint8Size = 1;
    uint256 internal constant uint16Size = 2;
    uint256 internal constant uint32Size = 4;
    uint256 internal constant uint64Size = 8;
    uint256 internal constant uint128Size = 16;
    uint256 internal constant uint256Size = 32;
    uint256 internal constant addressSize = 20;
    /**
     * Bits in 12 bytes.
     */
    uint256 private constant bytes12Bits = 96;

    function slice(bytes memory buffer, uint256 startIndex, uint256 length) internal pure returns (bytes memory) {
        unchecked {
            require(length + 31 >= length, "slice_overflow");
        }
        require(buffer.length >= startIndex + length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly ("memory-safe") {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(freeMemoryPtr)

            switch iszero(length)
            case 0 {
                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(length, maskModulo32)
                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let startOffset := add(lengthmod, mul(memoryWord, iszero(lengthmod)))

                let dst := add(tempBytes, startOffset)
                let end := add(dst, length)

                for { let src := add(add(buffer, startOffset), startIndex) } lt(dst, end) {
                    dst := add(dst, memoryWord)
                    src := add(src, memoryWord)
                } { mstore(dst, mload(src)) }

                // Update free-memory pointer
                // allocating the array padded to 32 bytes like the compiler does now
                // Note that negating bitwise the `maskModulo32` produces a mask that aligns addressing to 32 bytes.
                mstore(freeMemoryPtr, and(add(dst, maskModulo32), not(maskModulo32)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default { mstore(freeMemoryPtr, add(tempBytes, memoryWord)) }

            // Store the length of the buffer
            // We need to do it even if the length is zero because Solidity does not garbage collect
            mstore(tempBytes, length)
        }

        return tempBytes;
    }

    function toAddress(bytes memory buffer, uint256 startIndex) internal pure returns (address) {
        require(buffer.length >= startIndex + addressSize, "toAddress_outOfBounds");
        address tempAddress;

        assembly ("memory-safe") {
            // We want to shift into the lower 12 bytes and leave the upper 12 bytes clear.
            tempAddress := shr(bytes12Bits, mload(add(add(buffer, memoryWord), startIndex)))
        }

        return tempAddress;
    }

    function toUint8(bytes memory buffer, uint256 startIndex) internal pure returns (uint8) {
        require(buffer.length > startIndex, "toUint8_outOfBounds");

        // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
        uint256 startOffset = startIndex + uint8Size;
        uint8 tempUint;
        assembly ("memory-safe") {
            tempUint := mload(add(buffer, startOffset))
        }
        return tempUint;
    }

    function toUint16(bytes memory buffer, uint256 startIndex) internal pure returns (uint16) {
        uint256 endIndex = startIndex + uint16Size;
        require(buffer.length >= endIndex, "toUint16_outOfBounds");

        uint16 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toUint32(bytes memory buffer, uint256 startIndex) internal pure returns (uint32) {
        uint256 endIndex = startIndex + uint32Size;
        require(buffer.length >= endIndex, "toUint32_outOfBounds");

        uint32 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toUint64(bytes memory buffer, uint256 startIndex) internal pure returns (uint64) {
        uint256 endIndex = startIndex + uint64Size;
        require(buffer.length >= endIndex, "toUint64_outOfBounds");

        uint64 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toUint128(bytes memory buffer, uint256 startIndex) internal pure returns (uint128) {
        uint256 endIndex = startIndex + uint128Size;
        require(buffer.length >= endIndex, "toUint128_outOfBounds");

        uint128 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toUint256(bytes memory buffer, uint256 startIndex) internal pure returns (uint256) {
        uint256 endIndex = startIndex + uint256Size;
        require(buffer.length >= endIndex, "toUint256_outOfBounds");

        uint256 tempUint;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempUint := mload(add(buffer, endIndex))
        }
        return tempUint;
    }

    function toBytes32(bytes memory buffer, uint256 startIndex) internal pure returns (bytes32) {
        uint256 endIndex = startIndex + uint256Size;
        require(buffer.length >= endIndex, "toBytes32_outOfBounds");

        bytes32 tempBytes32;
        assembly ("memory-safe") {
            // Note that `endIndex == startOffset` for a given buffer due to the 32 bytes at the start that store the length.
            tempBytes32 := mload(add(buffer, endIndex))
        }
        return tempBytes32;
    }
}