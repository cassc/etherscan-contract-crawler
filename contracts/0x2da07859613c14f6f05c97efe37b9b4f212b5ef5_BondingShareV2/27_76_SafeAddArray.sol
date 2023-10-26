// SPDX-License-Identifier: MIT

// SPDX-License-Identifier: EUPL V1.2
pragma solidity ^0.8.3;

/**
 * @dev Wrappers over Solidity's array push operations with added check
 *
 */
library SafeAddArray {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     */
    function add(bytes32[] storage array, bytes32 value) internal {
        for (uint256 i; i < array.length; i++) {
            if (array[i] == value) {
                return;
            }
        }
        array.push(value);
    }

    function add(string[] storage array, string memory value) internal {
        bytes32 hashValue = keccak256(bytes(value));
        for (uint256 i; i < array.length; i++) {
            if (keccak256(bytes(array[i])) == hashValue) {
                return;
            }
        }
        array.push(value);
    }

    function add(uint256[] storage array, uint256 value) internal {
        for (uint256 i; i < array.length; i++) {
            if (array[i] == value) {
                return;
            }
        }
        array.push(value);
    }

    function add(uint256[] storage array, uint256[] memory values) internal {
        for (uint256 i; i < values.length; i++) {
            bool exist = false;
            for (uint256 j; j < array.length; j++) {
                if (array[j] == values[i]) {
                    exist = true;
                    break;
                }
            }
            if (!exist) {
                array.push(values[i]);
            }
        }
    }
}