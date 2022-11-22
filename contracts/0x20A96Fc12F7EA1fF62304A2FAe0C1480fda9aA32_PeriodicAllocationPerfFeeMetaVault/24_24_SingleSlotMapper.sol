// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title   A gas efficient library for mapping unique identifiers to indexes in an active array.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-09-16
 */
library SingleSlotMapper {
    /**
     * @dev Initialised all 62 vault indexes to 0xF which is an invalid value.
     * The last byte (8 bits) from the left is reserved for the number of indexes that have been issued
     * which is initialized to 0 hence there is 62 and not 64 Fs.
     */
    function initialize() internal pure returns (uint256 mapData_) {
        mapData_ = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    /**
     * @dev            Resolves the value of an index.
     * @param mapData  32 bytes (256 bits) of mapper data.
     * The left most byte contains the number of indexes mapped.
     * There are 62 4 bit values (248 bits) from right to left.
     * @param index    Value identifier between 0 and 61.
     * @return value   4 bit value where 0xF (15) is invalid.
     */
    function map(uint256 mapData, uint256 index) internal pure returns (uint256 value) {
        require(index < 62, "Index out of bounds");

        // Bit shift right by 4 bits (1/2 byte) for each index. eg
        // index 0 is not bit shifted
        // index 1 is shifted by 1 * 4 = 4 bits
        // index 3 is shifted by 3 * 4 = 12 bits
        // index 61 is shifted by 61 * 4 = 244 bits
        // A 0xF bit mask is used to cast the 4 bit number to a 256 number.
        // That is, the first 252 bits from the left are all set to 0.
        value = (mapData >> (index * 4)) & 0xF;
    }

    /**
     * @dev              Adds a mapping of a new index to a value.
     * @param  _mapData  32 bytes (256 bits) of map data.
     * @param  value     A 4 bit number between 0 and 14. 0xF (15) is invalid.
     * @return mapData_  Updated 32 bytes (256 bits) mapper data.
     * @return index     Index assigned to identify the added value.
     */
    function addValue(uint256 _mapData, uint256 value)
        internal
        pure
        returns (uint256 mapData_, uint256 index)
    {
        // value by be 14 or less as 0xF (15) is reserved for invalid.
        require(value < 0xF, "value out of bounds");

        // Right shift by 31 bytes * 8 bits (248 bits) to get the left most byte
        index = _mapData >> 248;
        require(index < 62, "map full");

        // Add the new number of indexed values to the left most byte.
        mapData_ = (index + 1) << 248;

        // Shift left and then right shift by 1 byte to clear the left most byte which has the previously set vault count.
        // OR with the previous map that has the number of vaults already set.
        mapData_ |= _mapData & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        // mapData_ |= (_mapData << 8) >> 8;

        // Clear the 4 bits of the mapped vault to all 0s.
        // Shift left by 4 bits for each index.
        // Negate (~) so we have a mask of all 1s except for the 4 bits we want to update next.
        // For example
        // index 0  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0
        // index 1  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0F
        // index 3  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0FFF
        // index 61 0xFF0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        mapData_ &= ~(0xF << (4 * index));

        // Add the 4 bit value to the indexed location.
        mapData_ |= value << (4 * index);
    }

    /**
     * @dev Removes a value from the mapped indexes and decrements all higher values
     * by one. Typically, this is used when the values are positions in an array and
     * one of the array items has been removed.
     */
    function removeValue(uint256 _mapData, uint256 removedValue)
        internal
        pure
        returns (uint256 mapData_)
    {
        require(removedValue < 0xF, "value out of bounds");

        mapData_ = _mapData;
        uint256 indexCount = _mapData >> 248;
        bool found = false;

        // For each index
        for (uint256 i = 0; i < indexCount; ) {
            uint256 offset = i * 4;

            // Read the mapped value
            uint256 value = (_mapData >> offset) & 0xF;
            if (value == removedValue) {
                mapData_ |= 0xF << offset;
                found = true;
            } else if (value < 0xF && value > removedValue) {
                // Clear the mapped underlying vault index
                mapData_ &= ~(0xF << offset);
                // Set the mapped underlying vault index to one less than the previous value
                mapData_ |= (value - 1) << offset;
            }

            unchecked {
                ++i;
            }
        }
        require(found == true, "value not found");
    }

    /**
     * @dev The total number of values that have been indexed including any removed values.
     * @param  _mapData  32 bytes (256 bits) of map data.
     * @return total     Number of values that have been indexed.
     */
    function indexes(uint256 _mapData) internal pure returns (uint256 total) {
        // Bit shift 31 bytes (31 * 8 = 248 bits) to the right.
        total = _mapData >> 248;
    }
}