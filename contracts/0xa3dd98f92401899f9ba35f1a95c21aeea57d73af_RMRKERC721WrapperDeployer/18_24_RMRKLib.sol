// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.21;

/**
 * @title RMRKLib
 * @author RMRK team
 * @notice RMRK library smart contract.
 */
library RMRKLib {
    /**
     * @notice Used to remove an item from the array using the specified index.
     * @dev The item is removed by replacing it with the last item and removing the last element.
     * @param array An array of items containing the item to be removed
     * @param index Index of the item to remove
     */
    function removeItemByIndex(uint64[] storage array, uint256 index) internal {
        //Check to see if this is already gated by require in all calls
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }

    /**
     * @notice Used to determine the index of the item in the array by spedifying its value.
     * @dev This was adapted from Cryptofin-Solidity `arrayUtils`.
     * @dev If the item is not found the index returned will equal `0`.
     * @param A The array containing the item to be found
     * @param a The value of the item to find the index of
     * @return The index of the item in the array
     * @return A boolean value specifying whether the item was found
     */
    function indexOf(
        uint64[] memory A,
        uint64 a
    ) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i; i < length; ) {
            if (A[i] == a) {
                return (i, true);
            }
            unchecked {
                ++i;
            }
        }
        return (0, false);
    }
}