// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title  PaddedString
 * @notice Borrows heavily from OpenZeppelin Strings contract:
 *         https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
 * @notice This library allows outputting an integer as a string of a fixed length with zero padding.
 */
library PaddedString {
    bytes16 private constant _SYMBOLS = "0123456789";
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation with zero padding.
     * Length is total string length returned.
     */
    function digitsToString(uint256 value, uint256 length) internal pure returns (string memory) {
        unchecked {
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
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (length-- == 0) break;
            }
            return buffer;
        }
    }

}