// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '../math/UncheckedMath.sol';

/**
 * @title Arrays
 * @dev Helper methods to operate arrays
 */
library Arrays {
    using UncheckedMath for uint256;

    /**
     * @dev Tells if an array of addresses includes the given ones
     */
    function includes(address[] memory arr, address a, address b) internal pure returns (bool) {
        bool containsA;
        bool containsB;
        for (uint256 i = 0; i < arr.length; i = i.uncheckedAdd(1)) {
            if (arr[i] == a) containsA = true;
            if (arr[i] == b) containsB = true;
        }
        return containsA && containsB;
    }

    /**
     * @dev Builds an array of addresses based on the given ones
     */
    function from(address a, address b) internal pure returns (address[] memory result) {
        result = new address[](2);
        result[0] = a;
        result[1] = b;
    }

    /**
     * @dev Builds an array of addresses based on the given ones
     */
    function from(address a, address[] memory b, address c) internal pure returns (address[] memory result) {
        // No need for checked math since we are simply adding one to a memory array's length
        result = new address[](b.length.uncheckedAdd(2));
        result[0] = a;

        // No need for checked math since we are using it to compute indexes manually, always within boundaries
        for (uint256 i = 0; i < b.length; i = i.uncheckedAdd(1)) result[i.uncheckedAdd(1)] = b[i];
        result[b.length.uncheckedAdd(1)] = c;
    }

    /**
     * @dev Builds an array of addresses based on the given ones
     */
    function from(address a, address[] memory b, address[] memory c) internal pure returns (address[] memory result) {
        // No need for checked math since we are simply adding two memory array's length
        result = new address[](b.length.uncheckedAdd(c.length).uncheckedAdd(1));
        result[0] = a;

        // No need for checked math since we are using it to compute indexes manually, always within boundaries
        for (uint256 i = 0; i < b.length; i = i.uncheckedAdd(1)) {
            result[i.uncheckedAdd(1)] = b[i];
        }

        // No need for checked math since we are using it to compute indexes manually, always within boundaries
        for (uint256 i = 0; i < c.length; i = i.uncheckedAdd(1)) {
            result[b.length.uncheckedAdd(1).uncheckedAdd(i)] = c[i];
        }
    }
}