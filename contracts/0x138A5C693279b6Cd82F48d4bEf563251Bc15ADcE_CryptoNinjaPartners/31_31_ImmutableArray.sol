// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for reading data of contract by SSTORE2 as immutable array.
/// @author 0xedy

//import "forge-std/console.sol";

library ImmutableArray {

    uint256 private constant _DATA_OFFSET = 1;
    uint256 private constant _HEADER_LENGTH = 3;
    
    uint256 private constant _BYTES_ARRAY_LENGTH_ADDRESS = 2;
    uint256 private constant _ADDRESS_SIZE_BYTES = 20;
    uint256 private constant _ADDRESS_OFFSET_BYTES = 12;
    uint256 private constant _UINT16_SIZE_BYTES = 4;
    uint256 private constant _UINT16_OFFSET_BYTES = 28;
    uint256 private constant _UINT256_SIZE_BYTES = 32;

    uint256 private constant _FORMAT_BYTES = 0x40;
    error InvalidPointer();

    error InconsistentArray();

    error FormatMismatch();

    error IndexOutOfBound();
    

    /**
     * @dev Reads header and code size of immutable array.
     */
    function readProperty(address pointer) 
        internal 
        view 
        returns (uint256 format, uint256 length, uint256 codeSize) 
    {
        assembly{
            codeSize := extcodesize(pointer)
            if lt(codeSize, add(_DATA_OFFSET, _HEADER_LENGTH)) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
        (format, length) = readProperty_unchecked(pointer);
    }

    /**
     * @dev Reads header and code size of immutable array without checking.
     */
    function readProperty_unchecked(address pointer) 
        internal 
        view 
        returns (uint256 format, uint256 length) 
    {
        /// @solidity memory-safe-assembly
        assembly {
            // reset scratch space
            mstore(0x00, 0)
            // copy data from pointer
            extcodecopy(
                pointer, 
                0, 
                _DATA_OFFSET, 
                _HEADER_LENGTH
            )
            // load header to stack
            let val := mload(0x00)
            // extract 8 bits in most left for packType
            format := shr(248, val)
            // extract next 16 bits for length
            length := shr(240, shl(8, val))
        }
    }
    function readUint256(address pointer, uint256 index) 
        internal 
        view 
        returns (uint256 ret, uint256 format, uint256 length, uint256 codeSize)
    {
        (format, length, codeSize) = readProperty(pointer);

        // Check the consistency of array and the validity of `index`.
        if (format > 32) revert FormatMismatch();
        if (format == 0) revert FormatMismatch();
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // Check boundary
        if (_HEADER_LENGTH + length * format + _DATA_OFFSET > codeSize) revert InconsistentArray();
        // Read value as uint256
        ret = readUint256_unchecked(pointer, index, format);
    }
    
    function readUint256Next(address pointer, uint256 index, uint256 format, uint256 length) 
        internal 
        view 
        returns (uint256 ret)
    {
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // Read value as uint256
        ret = readUint256_unchecked(pointer, index, format);
    }

    function readUint256_unchecked(address pointer, uint256 index, uint256 format) 
        internal 
        view 
        returns (uint256 ret)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // calculates start position
            let start := add(_HEADER_LENGTH, mul(format, index))
            // reset scratch space
            mstore(0x00, 0)
            // copy data from pointer
            extcodecopy(
                pointer, 
                sub(_UINT256_SIZE_BYTES, format), 
                add(start, _DATA_OFFSET), 
                format
            )
            // copy from memory to return stack
            ret := mload(0x00)
        }
    }

    /**
     * @dev Reads address at `index` in immutable array at first call in a function.
     * This function returns code size and header information from `pointer` contract.
     * Once call this, {readAddressNext} or {readAddressNext_unchecked} can be called to save gas.
     */
    function readAddress(address pointer, uint256 index) 
        internal 
        view 
        returns (address ret, uint256 length, uint256 codeSize) 
    {
        uint256 format;
        (format, length, codeSize) = readProperty(pointer);
        // Check format as address
        if (format != _ADDRESS_SIZE_BYTES) revert FormatMismatch();
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // Check boundary
        if (_HEADER_LENGTH + length * _ADDRESS_SIZE_BYTES + _DATA_OFFSET > codeSize) revert InconsistentArray();
        // read address
        ret = readAddress_unchecked(pointer, index);
    }

    /**
     * @dev Reads address at `index` in immutable array after first call in a function.
     * This function must be provided with lenght and codeSize from the first call.
     */
    function readAddressNext(address pointer, uint256 index, uint256 length) 
        internal 
        view 
        returns (address ret) 
    {
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // read address
        ret = readAddress_unchecked(pointer, index);
    }

    /**
     * @dev Reads address at `index` in immutable array after first call in a function.
     * This function must be provided with codeSize from the first call.
     * Also unchecking index bound to save gas.
     */
    function readAddress_unchecked(
        address pointer, 
        uint256 index
    ) internal view returns (address ret) {
        /// @solidity memory-safe-assembly
        assembly {
            // calculates start position
            let start := add(_HEADER_LENGTH, mul(_ADDRESS_SIZE_BYTES, index))
            // reset scratch space
            mstore(0x00, 0)
            // copy data from pointer
            extcodecopy(
                pointer, 
                _ADDRESS_OFFSET_BYTES, 
                add(start, _DATA_OFFSET), 
                _ADDRESS_SIZE_BYTES
            )
            // copy from memory to return stack
            ret := mload(0x00)
        }
    }

    /**
     * @dev Reads address at `index` in immutable array at first call in a function.
     * This function returns code size and header information from `pointer` contract.
     * Once call this, {readAddressNext} or {readAddressNext_unchecked} can be called to save gas.
     */
    function readUint16(address pointer, uint256 index) 
        internal 
        view 
        returns (uint16 ret, uint256 length, uint256 codeSize) 
    {
        uint256 format;
        (format, length, codeSize) = readProperty(pointer);
        // Check format as address
        if (format != _UINT16_SIZE_BYTES) revert FormatMismatch();
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // Check boundary
        if (_HEADER_LENGTH + length * _UINT16_SIZE_BYTES + _DATA_OFFSET > codeSize) revert InconsistentArray();
        // read address
        ret = readUint16_unchecked(pointer, index);
    }

    /**
     * @dev Reads address at `index` in immutable array after first call in a function.
     * This function must be provided with lenght and codeSize from the first call.
     */
    function readUint16Next(address pointer, uint256 index, uint256 length) 
        internal 
        view 
        returns (uint16 ret) 
    {
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // read address
        ret = readUint16_unchecked(pointer, index);
    }

    /**
     * @dev Reads address at `index` in immutable array after first call in a function.
     * This function must be provided with codeSize from the first call.
     * Also unchecking index bound to save gas.
     */
    function readUint16_unchecked(
        address pointer, 
        uint256 index
    ) internal view returns (uint16 ret) {
        /// @solidity memory-safe-assembly
        assembly {
            // calculates start position
            let start := add(_HEADER_LENGTH, mul(_UINT16_SIZE_BYTES, index))
            // reset scratch space
            mstore(0x00, 0)
            // copy data from pointer
            extcodecopy(
                pointer, 
                _UINT16_OFFSET_BYTES, 
                add(start, _DATA_OFFSET), 
                _UINT16_SIZE_BYTES
            )
            // copy from memory to return stack
            ret := mload(0x00)
        }
    }

    function readBytes(address pointer, uint256 index) 
        internal 
        view 
        returns (bytes memory ret, uint256 length, uint256 codeSize)
    {
        uint256 format;
        (format, length, codeSize) = readProperty(pointer);

        // Check the consistency of array and the validity of `index`.
        if (format != _FORMAT_BYTES) revert FormatMismatch();
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // Read last address.
        uint256 lastAddress = readUint256_unchecked(pointer, length - 1, _BYTES_ARRAY_LENGTH_ADDRESS);
        // Check size
        if (lastAddress + _DATA_OFFSET > codeSize) revert InconsistentArray();

        // read bytes data.
        ret = readBytes_unchecked(pointer, index, length);
    }

    function readBytesNext(address pointer, uint256 index, uint256 length) 
        internal 
        view 
        returns (bytes memory ret)
    {
        // Check the validity of `index`.
        if (index + 1 > length) revert IndexOutOfBound();
        // read bytes data.
        ret = readBytes_unchecked(pointer, index, length);
    }

    function readBytes_unchecked(address pointer, uint256 index, uint256 length) 
        internal 
        view 
        returns (bytes memory ret)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Read address list
            // start is the address one before index.
            // Since _HEADER_LENGTH > _BYTES_ARRAY_LENGTH_ADDRESS, 
            // start is not underflow even if index is zero.
            let start := add(
                sub(_HEADER_LENGTH, _BYTES_ARRAY_LENGTH_ADDRESS), 
                mul(index, _BYTES_ARRAY_LENGTH_ADDRESS)
            )
            // Extract list size is 2 addresses
            let size := mul(_BYTES_ARRAY_LENGTH_ADDRESS, 2)

             // reset scratch space
            mstore(0x00, 0)
            // copy address list from pointer to scratch space.
            extcodecopy(
                pointer, 
                sub(32, size), 
                add(start, _DATA_OFFSET), 
                size
            )
            // copy address list from scratch space to stack
            let list := mload(0x00)
            // Switch which index is zero.
            switch gt(index, 0) 
            case 1{
                // start is after address list.
                start := and(shr(mul(_BYTES_ARRAY_LENGTH_ADDRESS, 8), list), 0xFFFF)
            }
            default {
                // start is from lower of address list
                start := add(_HEADER_LENGTH, mul(length, _BYTES_ARRAY_LENGTH_ADDRESS))
            }
            // size = end - start
            size := sub(and(list, 0xFFFF), start)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            ret := mload(0x40)
            mstore(0x40, add(ret, and(add(size, 0x3f), 0xffe0)))
            mstore(ret, size)
            mstore(add(add(ret, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(ret, 0x20), add(start, _DATA_OFFSET), size)
        }
    }

}