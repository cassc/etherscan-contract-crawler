// SPDX-License-Identifier: MIT

/// @title Library for Bytes Manipulation
pragma solidity ^0.8.9;

library BytesLib {
    // TODO: Checks for the byte length
    // TODO: Check gas cost as single function vs. two functions
    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address tempAddress)
    {
        assembly {
            tempAddress := mload(add(add(_bytes, 0x14), _start))
        }
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256 amount)
    {
        assembly {
            amount := mload(add(add(_bytes, 0x20), _start))
        }
    }

    function toUint24(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint24 amount)
    {
        assembly {
            amount := mload(add(add(_bytes, 0x3), _start))
        }
    }

    function toUint16(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint16 amount)
    {
        assembly {
            amount := mload(add(add(_bytes, 0x2), _start))
        }
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8 amount)
    {
        assembly {
            amount := mload(add(add(_bytes, 0x1), _start))
        }
    }

    // TODO: May need to manipulate amountIn for bytes

    /// @param _bytes The bytes input
    /// @param _start The start index of the slice
    /// @param _length The length of the slice
   function sliceBytes(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory slicedBytes)
    {
        assembly {
                slicedBytes := mload(0x40)

                let lengthmod := and(_length, 31)
                
                let mc := add(add(slicedBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(slicedBytes, _length)
                mstore(0x40, and(add(mc, 31), not(31)))
        }
        return slicedBytes;
    }

    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }
}