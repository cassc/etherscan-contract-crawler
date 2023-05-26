// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @dev Library for a 4 bit per value map
 */
library BitMaps4 {
    struct BitMap4 {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns the value at `index`.
     */
    function get(BitMap4 storage bitmap, uint256 index) internal view returns (uint256) {
        uint256 bucket = index >> 6;
        uint256 idx = (index & 0x3f) << 2;
        return (bitmap._data[bucket] >> idx) & 0xf;
    }

    /**
     * @dev Sets the value at `index`.
     */
    function setTo(BitMap4 storage bitmap, uint256 index, uint256 value) internal {
        uint256 bucket = index >> 6;
        uint256 idx = (index & 0x3f) << 2;
        uint256 mask = ~(0xf << idx);
        bitmap._data[bucket] = (bitmap._data[bucket] & mask) | (value << idx);
    }
}