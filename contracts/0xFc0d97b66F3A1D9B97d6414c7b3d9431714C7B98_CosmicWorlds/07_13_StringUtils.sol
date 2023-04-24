// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library StringUtils {
    function uintToString(uint _i) internal pure returns (string memory str) {
        unchecked {
            if (_i == 0) {
                return "0";
            }

            uint j = _i;
            uint length;
            while (j != 0) {
                length++;
                j /= 10;
            }

            bytes memory bstr = new bytes(length);
            uint k = length;
            j = _i;
            while (j != 0) {
                bstr[--k] = bytes1(uint8(48 + j % 10));
                j /= 10;
            }
            
            str = string(bstr);
        }
    }

    function rgbString(uint red, uint green, uint blue) internal pure returns (string memory) {
        // return string(abi.encodePacked("rgb(", StringUtils.smallUintToString(red), ", ", StringUtils.smallUintToString(green), ", ", StringUtils.smallUintToString(blue), ")"));
        return string(abi.encodePacked("rgb(", StringUtils.uintToString(red), ", ", StringUtils.uintToString(green), ", ", StringUtils.uintToString(blue), ")"));
    }
}