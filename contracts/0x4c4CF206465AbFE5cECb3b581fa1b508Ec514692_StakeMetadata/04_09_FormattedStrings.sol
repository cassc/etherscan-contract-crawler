// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library FormattedStrings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
            Base on OpenZeppelin `toString` method from `String` library
     */
    function toFormattedString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        uint256 pos;
        uint256 comas = digits / 3;
        digits = digits + (digits % 3 == 0 ? comas - 1 : comas);
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            if (pos == 3) {
                buffer[digits] = ",";
                pos = 0;
            } else {
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
                pos++;
            }
        }
        return string(buffer);
    }
}