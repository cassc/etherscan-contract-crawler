// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringManipulation {
    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function hasEmptyString(string memory str) internal pure returns (bool) {
        for (uint i = 0; i < bytes(str).length; i++) {
            if (bytes(str)[i] == 0x20) {
                return true;
            }
        }
        return false;
    }

    function isEqual(string memory str1, string memory str2)
        internal
        pure
        returns (bool)
    {
        bool res = false;
        if (
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2))
        ) {
            res = true;
        }
        return res;
    }
}