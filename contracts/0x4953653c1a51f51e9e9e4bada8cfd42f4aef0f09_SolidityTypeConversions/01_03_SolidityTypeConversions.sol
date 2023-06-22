// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.6.12;

import {ChecksummedAddress as ca} from "./ChecksummedAddress.sol";
import {Math as m} from "./Math.sol";

library SolidityTypeConversions {
    /**
     * @dev Converts `bytes` to `bytes32`.
     * @param src The input.
     * @return dst The converted value. If `src` is larger than 32 bytes, the result is truncated.
     */
    function toBytes32(bytes memory src) internal pure returns (bytes32 dst) {
        if (src.length == 0) {
            return 0x0;
        }

        assembly {
            dst := mload(add(src, 32))
        }
    }

    /**
     * @dev Converts a `string` to `bytes32`.
     * @param src The input.
     * @return dst The converted value. If `src` is larger than 32 characters, the result is truncated.
     */
    function toBytes32(string memory src) internal pure returns (bytes32 dst) {
        return toBytes32(abi.encodePacked(src));
    }

    /**
     * @dev Converts a `bytes32` to its ASCII `string` representation.
     * @param src The input.
     * @return result The string representation.
     */
    function toString(bytes32 src) internal pure returns (string memory result) {
        uint8 length = 0;
        while (src[length] != 0 && length < 32) {
            length++;
        }
        assembly {
            result := mload(0x40)
            // new "memory end" including padding (the string isn't larger than 32 bytes)
            mstore(0x40, add(result, 0x40))
            // store length in memory
            mstore(result, length)
            // write actual data
            mstore(add(result, 0x20), src)
        }
    }

    /**
     * @dev Converts an `address` to its ASCII `string` checksummed representation.
     * @param src The input.
     * @return result The string representation.
     */
    function toString(address src) public pure returns (string memory) {
        return string(abi.encodePacked("0x", ca.toChecksum(src)));
    }

    /**
     * Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6a8d977d2248cf1c115497fccfd7a2da3f86a58f/contracts/utils/Strings.sol#L18-L38

     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     * @param src The input.
     * @return result The string representation.
     */
    function toString(uint256 src) internal pure returns (string memory) {
        uint256 length = m.log10(src) + 1;
        string memory buffer = new string(length);
        uint256 ptr;
        /// @solidity memory-safe-assembly
        assembly {
            ptr := add(buffer, add(32, length))
        }
        while (true) {
            ptr--;
            /// @solidity memory-safe-assembly
            assembly {
                mstore8(ptr, byte(mod(src, 10), "0123456789abcdef"))
            }
            src /= 10;
            if (src == 0) break;
        }
        return buffer;
    }
}