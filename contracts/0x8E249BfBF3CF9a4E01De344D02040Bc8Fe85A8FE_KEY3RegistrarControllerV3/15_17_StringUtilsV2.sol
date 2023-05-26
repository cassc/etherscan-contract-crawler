// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library StringUtilsV2 {
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        bytes memory b = bytes(s);
        for (len = 0; i < b.length; len++) {
            bytes1 char = b[i];
            if (char < 0x80) {
                i += 1;
            } else if (char < 0xE0) {
                i += 2;
            } else if (char < 0xF0) {
                i += 3;
            } else if (char < 0xF8) {
                i += 4;
            } else if (char < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }

    function onlyContainNumbers(string memory s) internal pure returns (bool) {
        bytes memory b = bytes(s);
        if (b.length == 0) {
            return false;
        }

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (!(char >= 0x30 && char <= 0x39)) {
                return false;
            }
        }

        return true;
    }

    function onlyContainLetters(string memory s) internal pure returns (bool) {
        bytes memory b = bytes(s);
        if (b.length == 0) {
            return false;
        }

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (
                !(char >= 0x41 && char <= 0x5A) &&
                !(char >= 0x61 && char <= 0x7A)
            ) {
                return false;
            }
        }

        return true;
    }

    function onlyContainNumbersAndLetters(
        string memory s
    ) internal pure returns (bool) {
        bytes memory b = bytes(s);
        if (b.length == 0) {
            return false;
        }

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (
                !(char >= 0x30 && char <= 0x39) &&
                !(char >= 0x41 && char <= 0x5A) &&
                !(char >= 0x61 && char <= 0x7A)
            ) {
                return false;
            }
        }

        return true;
    }

    function toLowerCase(
        string memory s
    ) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        bytes memory lowers = new bytes(b.length);
        for (uint i = 0; i < b.length; i++) {
            bytes1 char = b[i];
            if (char >= 0x41 && char <= 0x5A) {
                lowers[i] = bytes1(uint8(char) + 0x20);
            } else {
                lowers[i] = b[i];
            }
        }
        return string(lowers);
    }
}