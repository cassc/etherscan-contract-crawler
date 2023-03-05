// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library HexStringsV2 {
    function uint2hexstr(uint256 i) internal pure returns (string memory) {
        if (i == 0) return "0000000000000000000000000000000000000000000000000000000000000000";
        uint256 length = 64;
        uint256 mask = 15;
        bytes memory bstr = new bytes(length);
        uint256 j = length;
        while (j != 0) {
            uint256 curr = (i & mask);
            bstr[--j] = curr > 9 ? bytes1(uint8(87 + curr)) : bytes1(uint8(48 + curr));
            i = i >> 4;
        }
        return string(bstr);
    }
}