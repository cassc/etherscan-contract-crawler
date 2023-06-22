// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Bitmap
/// @author Boffee - Critterz
/// @notice Storage efficient index -> boolean map
library Bitmap {
    uint256 internal constant BITS_PER_SLOT = 256;

    function set(
        mapping(uint256 => uint256) storage map,
        uint256 key,
        bool value
    ) internal {
        uint256 index = _getIndex(key);
        uint256 bitMask = _getBitMask(key);
        if (value) {
            map[index] |= bitMask;
        } else {
            map[index] ^= bitMask;
        }
    }

    function multiSet(
        mapping(uint256 => uint256) storage map,
        uint256[] memory keys,
        bool value
    ) internal {
        uint256 index = _getIndex(keys[0]);
        uint256 bitMask = _getBitMask(keys[0]);
        for (uint256 i = 1; i < keys.length; i++) {
            uint256 newIndex = _getIndex(keys[i]);
            uint256 newBitMask = _getBitMask(keys[i]);
            if (newIndex == index) {
                bitMask += newBitMask;
            } else {
                if (value) {
                    map[index] |= bitMask;
                } else {
                    map[index] ^= bitMask;
                }
                index = newIndex;
                bitMask = newBitMask;
            }
        }
        if (value) {
            map[index] |= bitMask;
        } else {
            map[index] ^= bitMask;
        }
    }

    function get(mapping(uint256 => uint256) storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        uint256 index = _getIndex(key);
        uint256 bitMask = _getBitMask(key);
        return (map[index] & bitMask) != 0;
    }

    function _getIndex(uint256 key) private pure returns (uint256) {
        return key / BITS_PER_SLOT;
    }

    function _getBitMask(uint256 key) private pure returns (uint256) {
        return 1 << (key % BITS_PER_SLOT);
    }
}