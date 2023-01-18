// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity 0.8.11;

/**
 * @dev String operations.
 */
library StringsW0x {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    
    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        int256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, int256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * uint256(length));
        for (int256 i = 2 * length - 1; i > -1; --i) {
            buffer[uint256(i)] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}