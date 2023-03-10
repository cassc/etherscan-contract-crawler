// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

library LibBase58 {
    bytes constant ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    function toBase58(bytes memory source) internal pure returns (bytes memory) {
        if (source.length == 0) return new bytes(0);
        uint8[] memory digits = new uint8[](64);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint256 i = 0; i < source.length; ++i) {
            uint256 carry = uint8(source[i]);
            for (uint256 j = 0; j < digitlength; ++j) {
                carry += uint256(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }

            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        return _toAlphabet(_reverse(_truncate(digits, digitlength)));
    }

    function concat(bytes memory byteArray, bytes memory byteArray2) internal pure returns (bytes memory) {
        bytes memory returnArray = new bytes(byteArray.length + byteArray2.length);
        uint256 i = 0;
        for (i; i < byteArray.length; i++) {
            returnArray[i] = byteArray[i];
        }
        for (i; i < (byteArray.length + byteArray2.length); i++) {
            returnArray[i] = byteArray2[i - byteArray.length];
        }
        return returnArray;
    }

    function _truncate(uint8[] memory array, uint8 length) private pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = array[i];
        }
        return output;
    }

    function _reverse(uint8[] memory input) private pure returns (uint8[] memory) {
        uint8[] memory output = new uint8[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }

    function _toAlphabet(uint8[] memory indices) private pure returns (bytes memory) {
        bytes memory output = new bytes(indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = ALPHABET[indices[i]];
        }
        return output;
    }

    function _toBinary(uint256 x) private pure returns (bytes memory) {
        if (x == 0) {
            return new bytes(0);
        } else {
            bytes1 s = bytes1(uint8(x % 256));
            bytes memory r = new bytes(1);
            r[0] = s;
            return concat(_toBinary(x / 256), r);
        }
    }
}