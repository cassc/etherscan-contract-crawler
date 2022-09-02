// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";

library ArrayUtil {

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value less or equal to `element`.
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findLowerBound(uint256[] memory array, uint256 element) internal pure returns (bool, uint256) {
        if (array.length == 0) {
            // Nothing in the array
            return (false, 0);
        }
        if (element < array[0]) {
            // Out of array range
            return (false, 0);
        }

        uint256 low = 0;
        uint256 high = array.length;
        uint256 mid;

        // The looping is limited as 256. In fact, this looping will be early broken because the maximum slot count is 2^256
        for (uint16 i = 0; i < 256; i ++) {
            mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (element < array[mid]) {
                high = mid;
            } else if (element == array[mid] || low == mid) {
                // Found the correct element
                // Or the array[low] is the less and the nearest value to the element
                break;
            } else {
                low = mid;
            }
        }
        return (true, mid);
    }
}