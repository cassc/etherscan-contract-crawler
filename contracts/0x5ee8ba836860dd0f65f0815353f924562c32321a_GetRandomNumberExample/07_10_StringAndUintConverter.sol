// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

function uintToString(uint256 v) pure returns (string memory str) {
    uint256 maxlength = 100;
    bytes memory reversed = new bytes(maxlength);
    uint256 i = 0;
    while (v != 0) {
        uint256 remainder = v % 10;
        v = v / 10;
        reversed[i++] = bytes1(uint8(48 + remainder));
    }
    bytes memory s = new bytes(i + 1);
    for (uint256 j = 0; j <= i; j++) {
        s[j] = reversed[i - j];
    }
    str = string(s);
}

function stringToUint(string memory s) pure returns (uint256 result) {
    bytes memory b = bytes(s);
    uint256 i;
    result = 0;
    for (i = 0; i < b.length; i++) {
        uint256 c = uint256(uint8(b[i]));
        if (c >= 48 && c <= 57) {
            result = result * 10 + (c - 48);
        }
    }
}