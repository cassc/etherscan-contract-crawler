// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Bitmap utilities
 */
library BitmapUtils {
    function get(uint256 bitmap, uint256 index) internal pure returns (uint256) {
        return (bitmap >> index) & 1;
    }

    function isSet(uint256 bitmap, uint256 index) internal pure returns (bool) {
        return get(bitmap, index) == 1;
    }

    function set(uint256 bitmap, uint256 index) internal pure returns (uint256) {
        return bitmap | (1 << index);
    }

    function setRange(uint256 bitmap, uint256 offset, uint256 amount) internal pure returns (uint256) {
        return bitmap | (((1 << amount) - 1) << offset);
    }

    function unset(uint256 bitmap, uint256 index) internal pure returns (uint256) {
        return bitmap & toggle(type(uint256).max, index);
    }
    
    function unsetRange(uint256 bitmap, uint256 offset, uint256 amount) internal pure returns (uint256) {
        return bitmap & toggleRange(type(uint256).max, offset, amount);
    }

    function toggle(uint256 bitmap, uint256 index) internal pure returns (uint256) {
        return bitmap ^ (1 << index);
    }

    function toggleRange(uint256 bitmap, uint256 offset, uint256 amount) internal pure returns (uint256) {
        return bitmap ^ (((1 << amount) - 1) << offset);
    }
}