// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

library GIF32 {

    bytes6 constant private HEADER = 0x474946383961;
    bytes1 constant private FOOTER = 0x3b;
    bytes8 constant private TRANSPARENT = 0x21f9040100000000; // palette index 0 is transparent
    bytes19 constant private ANIMATION = 0x21FF0B4E45545343415045322E300301000000;
    bytes3 constant private GCE_PREFIX = 0x21f904;

    function gce10x (bool disposeClear, uint8 delay, uint8 transparentColorIndex) internal pure returns (bytes memory) {
        uint d = uint256(delay) * 10;
        uint8 delay1 = uint8(d & 255);
        uint8 delay2 = uint8((d >> 8) & 255);
        return abi.encodePacked(GCE_PREFIX,
                                uint8(disposeClear ? 9 : 5),
                                uint8(delay1),
                                uint8(delay2),
                                transparentColorIndex,
                                uint8(0));
    }


    function gce (bool disposeClear, uint8 delay, uint8 transparentColorIndex) internal pure returns (bytes memory) {
        return abi.encodePacked(GCE_PREFIX,
                                uint8(disposeClear ? 9 : 5),
                                uint8(delay),
                                uint8(0),
                                transparentColorIndex,
                                uint8(0));
    }

    function gce (bool disposeClear, uint8 delay) internal pure returns (bytes memory) {
        return abi.encodePacked(GCE_PREFIX,
                                uint8(disposeClear ? 8 : 4),
                                uint8(delay),
                                uint24(0));
    }

    function _frame (uint8 x, uint8 y, uint8 w, uint8 h, uint8 mcs, bytes memory lct_data, bytes memory chunks) private pure returns (bytes memory) {
        return abi.encodePacked(uint8(0x2c),
                                x, uint8(0),
                                y, uint8(0),
                                w, uint8(0),
                                h, uint8(0),
                                lct_data,
                                mcs,
                                chunks,
                                uint8(0));
    }

    function frame (uint8 x, uint8 y, uint8 w, uint8 h, uint8 mcs, bytes memory chunks) internal pure returns (bytes memory) {
        return _frame(x, y, w, h, mcs, abi.encodePacked(uint8(0)), chunks);
    }

    function frame (uint8 x, uint8 y, uint8 w, uint8 h, uint8 mcs, bytes memory chunks, bytes memory lct) internal pure returns (bytes memory) {
        return _frame(x, y, w, h, mcs, abi.encodePacked(uint8(240 + mcs - 1), lct), chunks);
    }

    function _assembleStatic (uint8 width, uint8 height, bool transparency, bytes memory frames, bytes memory gct_data) private pure returns (bytes memory) {
        bytes memory transparent = transparency ? abi.encodePacked(TRANSPARENT) : bytes("");
        return abi.encodePacked(HEADER,
                                width, uint8(0),
                                height, uint8(0),
                                gct_data,
                                transparent,
                                frames,
                                FOOTER);
    }

    function assembleStatic (uint8 width, uint8 height, bool transparency, bytes memory frames) internal pure returns (bytes memory) {
        return _assembleStatic(width, height, transparency, frames, abi.encodePacked(uint24(0)));
    }

    function assembleStatic (uint8 width, uint8 height, bool transparency, bytes memory frames, uint8 mcs, bytes memory gct) internal pure returns (bytes memory) {
        return _assembleStatic(width, height, transparency, frames, abi.encodePacked(uint8(240 + mcs - 1), uint16(0), gct));
    }

    function _assembleAnimated (uint8 width, uint8 height, bytes memory framedata, bytes memory gct_data) private pure returns (bytes memory) {
        return abi.encodePacked(HEADER,
                                width, uint8(0),
                                height, uint8(0),
                                gct_data,
                                ANIMATION,
                                framedata,
                                FOOTER);
    }

    function assembleAnimated (uint8 width, uint8 height, bytes memory framedata) internal pure returns (bytes memory) {
        return _assembleAnimated(width, height, framedata, abi.encodePacked(uint24(0)));
    }

    function assembleAnimated (uint8 width, uint8 height, bytes memory framedata, uint8 mcs, bytes memory gct) internal pure returns (bytes memory) {
        return _assembleAnimated(width, height, framedata, abi.encodePacked(uint8(240 + mcs - 1), uint16(0), gct));
    }
}