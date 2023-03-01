// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library HexStrings {
    function uint2hexstr(uint256 i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint256 mask = 15;
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (i != 0) {
            uint256 curr = (i & mask);
            bstr[--k] = curr > 9 ? bytes1(uint8(87 + curr)) : bytes1(uint8(48 + curr));
            i = i >> 4;
        }
        return string(bstr);
    }
}