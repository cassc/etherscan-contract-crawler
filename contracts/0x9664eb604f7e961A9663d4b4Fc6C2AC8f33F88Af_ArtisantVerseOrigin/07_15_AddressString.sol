// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0;

library AddressString {
    // converts an address to the uppercase hex string, extracting only len bytes (up to 20, multiple of 2)
    function toAsciiString(address addr) internal pure returns (string memory) {
        bytes memory s = new bytes(42);
        uint160 addrNum = uint160(addr);
        s[0] = '0';
        s[1] = 'X';
        for (uint256 i = 0; i < 40 / 2; i++) {
            // shift right and truncate all but the least significant byte to extract the byte at position 19-i
            uint8 b = uint8(addrNum >> (8 * (19 - i)));
            // first hex character is the most significant 4 bits
            uint8 hi = b >> 4;
            // second hex character is the least significant 4 bits
            uint8 lo = b - (hi << 4);
            s[2 * i + 2] = char(hi);
            s[2 * i + 3] = char(lo);
        }
        return string(s);
    }

    // hi and lo are only 4 bits and between 0 and 16
    // this method converts those values to the unicode/ascii code point for the hex representation
    // uses upper case for the characters
    function char(uint8 b) private pure returns (bytes1 c) {
        if (b < 10) {
            return bytes1(b + 0x30);
        } else {
            return bytes1(b + 0x37);
        }
    }
}