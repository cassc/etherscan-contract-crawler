// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library ColorUtils {
    function uint2str(uint256 i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }
        uint256 j = i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(i - i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            i /= 10;
        }
        return string(bstr);
    }

    function uint2hex(uint24 i) internal pure returns (string memory) {
        bytes memory o = new bytes(6);
        uint24 mask = 0x00000f; // hex 15
        uint256 k = 6;
        do {
            k--;
            uint8 masked = uint8(i & mask);
            o[k] = bytes1((masked > 9) ? (masked + 87) : (masked + 48)); // ASCII a-f => +87 | 0-9 => +48
            i >>= 4;
        } while (k > 0);

        return string(o);
    }
}