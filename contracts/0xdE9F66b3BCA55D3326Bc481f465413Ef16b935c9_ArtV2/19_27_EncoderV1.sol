// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

library EncoderV1 {
    using Strings for uint;

    function encodeDecimals(uint num) internal pure returns (bytes memory) {
        bytes memory decimals = bytes((num % 1e18).toString());
        uint length = decimals.length;

        for (uint i = length; i < 18; i += 1) {
            decimals = abi.encodePacked('0', decimals);
        }

        return abi.encodePacked(
            (num / 1e18).toString(),
            '.',
            decimals
        );
    }

    function encodeAddress(address addr) internal pure returns (bytes memory) {
        if (addr == address(0)) {
            return 'null';
        }

        return abi.encodePacked(
            '"', uint(uint160(addr)).toHexString(), '"'
        );
    }

    function encodeColorValue(uint8 colorValue) internal pure returns (bytes memory) {
        bytes memory hexValue = new bytes(2);
        bytes memory hexChars = "0123456789abcdef";
        hexValue[0] = hexChars[colorValue / 16];
        hexValue[1] = hexChars[colorValue % 16];
        return hexValue;
    }

    function encodeColor(uint color) internal pure returns (bytes memory) {
        uint8 r = uint8(color >> 24);
        uint8 g = uint8(color >> 16);
        uint8 b = uint8(color >> 8);
        // uint8 a = uint8(color);

        return abi.encodePacked(
            '#',
             encodeColorValue(r),
             encodeColorValue(g),
             encodeColorValue(b)
        );
    }

    function encodeUintArray(uint[] memory arr) internal pure returns (string memory) {
        bytes memory values;
        uint total = arr.length;

        for (uint i = 0; i < total; i += 1) {
            uint v = arr[i];
            if (i == total - 1) {
                values = abi.encodePacked(values, v.toString());
            } else {
                values = abi.encodePacked(values, v.toString(), ',');
            }
        }

        return string(abi.encodePacked('[', values ,']'));
    }

    function encodeDecimalArray(uint[] memory arr) internal pure returns (string memory) {
        bytes memory values;
        uint total = arr.length;

        for (uint i = 0; i < total; i += 1) {
            uint v = arr[i];
            if (i == total - 1) {
                values = abi.encodePacked(values, encodeDecimals(v));
            } else {
                values = abi.encodePacked(values, encodeDecimals(v), ',');
            }
        }

        return string(abi.encodePacked('[', values ,']'));
    }
}