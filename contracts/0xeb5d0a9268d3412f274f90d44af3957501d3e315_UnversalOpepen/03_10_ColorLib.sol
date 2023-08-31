// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library ColorLib {
    function packColor(uint256 data, uint256 slot, uint24 color) internal pure returns (uint256 retData) {
        assembly ("memory-safe") {
            let startOffset := 2
            if gt(slot, 9) {
                slot := sub(slot, 10)
                startOffset := 0
            }
            let offset := add(mul(slot, 24), startOffset)
            data := and(data, not(shl(offset, 0xFFFFFF)))
            retData := or(data, shl(offset, color))
        }
    }

    function unpackColor(uint256 tokenData, uint256 slot) internal pure returns (uint24 color) {
        assembly ("memory-safe") {
            let startOffset := 2
            if gt(slot, 9) {
                slot := sub(slot, 10)
                startOffset := 0
            }
            color := and(shr(add(mul(slot, 24), startOffset), tokenData), 0xFFFFFF)
        }
    }

    function packBackground(uint256 data, uint256 data2, uint24 background)
        internal
        pure
        returns (uint256 retData, uint256 retData2)
    {
        assembly ("memory-safe") {
            data := and(data, not(shl(242, 0xFF)))
            data2 := and(data2, not(shl(240, 0xFFFF)))

            retData := or(data, shl(242, and(background, 0xFF)))
            retData2 := or(data2, shl(240, and(shr(8, background), 0xFFFF)))
        }
    }

    function unpackBackground(uint256 tokenData, uint256 tokenData2) internal pure returns (uint24 background) {
        assembly ("memory-safe") {
            background := and(shr(242, tokenData), 0xFF)
            background := or(background, shl(8, and(shr(240, tokenData2), 0xFFFF)))
        }
    }
}