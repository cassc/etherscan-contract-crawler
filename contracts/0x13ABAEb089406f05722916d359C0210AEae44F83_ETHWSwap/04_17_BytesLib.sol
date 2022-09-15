// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @title Bytes
 * @dev Helper functions to operate with bytes arrays
 */
library Bytes {
    /**
     * @dev Tells if a bytes array is empty or not
     */
    function isEmpty(bytes memory self) internal pure returns (bool) {
        return self.length == 0;
    }

    /**
     * @dev Concatenates an address to a bytes array
     */
    function concat(bytes memory self, address value) internal pure returns (bytes memory) {
        return abi.encodePacked(self, value);
    }

    /**
     * @dev Concatenates an uint24 to a bytes array
     */
    function concat(bytes memory self, uint24 value) internal pure returns (bytes memory) {
        return abi.encodePacked(self, value);
    }
}