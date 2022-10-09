// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.17;

import { SafeMath } from './SafeMath.sol';

/**
* @dev String operations.
*/
library Strings {
    using SafeMath for uint256;
    bytes16 private constant _SYMBOLS = "0123456789abcdef"; 

    /**
        * @dev Converts a `uint256` to its ASCII `string` decimal representation.
    */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = SafeMath.log10(value) + 1;
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
                if (value == 0) break;
            }
            return buffer;
        }
    }
}