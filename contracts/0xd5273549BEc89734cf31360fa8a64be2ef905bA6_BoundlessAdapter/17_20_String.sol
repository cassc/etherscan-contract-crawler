// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

/// Library with common String checks.
library String {
    /// Check that the string only contains alphanumeric characters, to avoid
    /// UTF-8 characters that are indistinguishable from alphanumeric
    /// characters.
    function isAlphanumeric(string memory str) internal pure returns (bool) {
        for (uint256 i = 0; i < bytes(str).length; i++) {
            uint8 char = uint8(bytes(str)[i]);
            if (!((char >= 65 && char <= 90) || (char >= 97 && char <= 122) || (char >= 48 && char <= 57))) {
                return false;
            }
        }
        return true;
    }

    /// Check that the string has at least one character.
    function isNotEmpty(string memory str) internal pure returns (bool) {
        return bytes(str).length > 0;
    }

    /// Check that the string is not empty and only has alphanumeric characters.
    function isValidString(string memory str) internal pure returns (bool) {
        return isNotEmpty(str) && isAlphanumeric(str);
    }
}