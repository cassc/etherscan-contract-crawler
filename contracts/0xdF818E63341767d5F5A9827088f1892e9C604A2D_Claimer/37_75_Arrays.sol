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

import '@mimic-fi/v2-helpers/contracts/math/UncheckedMath.sol';

/**
 * @title Arrays
 * @dev Helper methods to operate arrays
 */
library Arrays {
    using UncheckedMath for uint256;

    /**
     * @dev Builds an array of addresses based on the given ones
     */
    function concat(address[] memory a, address[] memory b) internal pure returns (address[] memory r) {
        // No need for checked math since we are simply adding two memory array's length
        r = new address[](a.length.uncheckedAdd(b.length));

        // No need for checked math since we are using it to compute indexes manually, always within boundaries
        for (uint256 i = 0; i < a.length; i = i.uncheckedAdd(1)) {
            r[i] = a[i];
        }

        // No need for checked math since we are using it to compute indexes manually, always within boundaries
        for (uint256 i = 0; i < b.length; i = i.uncheckedAdd(1)) {
            r[a.length.uncheckedAdd(i)] = b[i];
        }
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

    // Address helpers

    function from(address a) internal pure returns (address[] memory r) {
        r = new address[](1);
        r[0] = a;
    }

    function from(address a, address b) internal pure returns (address[] memory r) {
        r = new address[](2);
        r[0] = a;
        r[1] = b;
    }

    function from(address a, address b, address c) internal pure returns (address[] memory r) {
        r = new address[](3);
        r[0] = a;
        r[1] = b;
        r[2] = c;
    }

    function from(address a, address b, address c, address d) internal pure returns (address[] memory r) {
        r = new address[](4);
        r[0] = a;
        r[1] = b;
        r[2] = c;
        r[3] = d;
    }

    function from(address a, address b, address c, address d, address e) internal pure returns (address[] memory r) {
        r = new address[](5);
        r[0] = a;
        r[1] = b;
        r[2] = c;
        r[3] = d;
        r[4] = e;
    }

    // Bytes4 helpers

    function from(bytes4 a) internal pure returns (bytes4[] memory r) {
        r = new bytes4[](1);
        r[0] = a;
    }

    function from(bytes4 a, bytes4 b) internal pure returns (bytes4[] memory r) {
        r = new bytes4[](2);
        r[0] = a;
        r[1] = b;
    }

    function from(bytes4 a, bytes4 b, bytes4 c) internal pure returns (bytes4[] memory r) {
        r = new bytes4[](3);
        r[0] = a;
        r[1] = b;
        r[2] = c;
    }

    function from(bytes4 a, bytes4 b, bytes4 c, bytes4 d) internal pure returns (bytes4[] memory r) {
        r = new bytes4[](4);
        r[0] = a;
        r[1] = b;
        r[2] = c;
        r[3] = d;
    }

    function from(bytes4 a, bytes4 b, bytes4 c, bytes4 d, bytes4 e) internal pure returns (bytes4[] memory r) {
        r = new bytes4[](5);
        r[0] = a;
        r[1] = b;
        r[2] = c;
        r[3] = d;
        r[4] = e;
    }
}