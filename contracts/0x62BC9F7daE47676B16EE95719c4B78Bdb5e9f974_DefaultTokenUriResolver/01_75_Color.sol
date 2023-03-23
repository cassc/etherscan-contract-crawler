// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Types.sol";
import "./Create.sol";

library LibColor {

    function toBytes3(Color c) internal pure returns (bytes3) {
        return Color.unwrap(c);
    }

    function toRGB(Color c) internal pure returns (uint8 red, uint8 green, uint8 blue) {
        return (
            uint8(uint24(Color.unwrap(c)) >> 16),
            uint8(uint24(Color.unwrap(c)) >> 8),
            uint8(uint24(Color.unwrap(c)))
        );
    }

    // https://stackoverflow.com/a/69316712
    function toString(Color c) internal pure returns(string memory){
        bytes memory o = new bytes(6);
        o[5] = bytes1(uint8tohexchar(uint8(uint24(Color.unwrap(c)) & 0xf)));
        o[4] = bytes1(uint8tohexchar(uint8(uint24(Color.unwrap(c)) >> 4 & 0xf)));
        o[3] = bytes1(uint8tohexchar(uint8(uint24(Color.unwrap(c)) >> 8 & 0xf)));
        o[2] = bytes1(uint8tohexchar(uint8(uint24(Color.unwrap(c)) >> 12 & 0xf)));
        o[1] = bytes1(uint8tohexchar(uint8(uint24(Color.unwrap(c)) >> 16 & 0xf)));
        o[0] = bytes1(uint8tohexchar(uint8(uint24(Color.unwrap(c)) >> 20 & 0xf)));
        return string(o);
    }

    function uint8tohexchar(uint8 i) private pure returns (uint8) {
        unchecked{
            return (i > 9) ?
                (i + 55) : // ascii A-F
                (i + 48); // ascii 0-9
        }
    }
}