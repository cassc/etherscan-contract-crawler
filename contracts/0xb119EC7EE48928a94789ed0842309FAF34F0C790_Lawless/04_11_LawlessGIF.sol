// SPDX-License-Identifier: AGPL-3.0
// ©2023 Ponderware Ltd

pragma solidity ^0.8.17;

import "../../lib/Base64.sol";
import "../../lib/ItemStorage.sol";
import "../../lib/image/GIF32.sol";
import "solmate/src/utils/SSTORE2.sol";

struct Model {
    uint8 width;
    uint8 height;
    uint8 aniX;
    uint8 aniY;
    uint8 aniWidth;
    uint8 aniHeight;
    uint8 aniDelay1;
    uint8 aniDelay2;
    uint8 aniDelay3;
    uint8 staticWidth;
    uint8 staticHeight;
    uint8 staticOffsetX;
    uint8 staticOffsetY;
    uint8 maxScale;
    bytes f1;
    bytes f2;
    bytes f3;
    bytes f4;
}

contract LawlessGIF {

    /* Data Stores */

    ItemStorage.Store internal ModelData;
    ItemStorage.Store internal PaletteData;

    /* Unpack Models */

    function slice(uint begin, uint len, bytes memory arr) internal pure returns (bytes memory) {
        bytes memory res = new bytes(len);
        for (uint i = 0; i < len; i++) {
            res[i] = arr[i+begin];
        }
        return res;
    }

    function slice2(uint loc, bytes memory arr) internal pure returns (uint) {
        uint res = uint(uint8(arr[loc])) << 8;
        return (res + uint8(arr[loc + 1]));
    }

    function unpackModel (bytes memory input) internal pure returns (Model memory) {

        uint pointer = 14;
        uint len = slice2(pointer, input);
        pointer += 2;
        bytes memory f1 = slice(pointer, len, input);

        pointer += len;
        len = slice2(pointer, input);
        pointer += 2;
        bytes memory f2 = slice(pointer, len, input);

        pointer += len;
        len = slice2(pointer, input);
        pointer += 2;
        bytes memory f3 = slice(pointer, len, input);

        pointer += len;
        len = slice2(pointer, input);
        pointer += 2;
        bytes memory f4 = slice(pointer, len, input);

        return Model(uint8(bytes1(input[0])),
                     uint8(bytes1(input[1])),
                     uint8(bytes1(input[2])),
                     uint8(bytes1(input[3])),
                     uint8(bytes1(input[4])),
                     uint8(bytes1(input[5])),
                     uint8(bytes1(input[6])),
                     uint8(bytes1(input[7])),
                     uint8(bytes1(input[8])),
                     uint8(bytes1(input[9])),
                     uint8(bytes1(input[10])),
                     uint8(bytes1(input[11])),
                     uint8(bytes1(input[12])),
                     uint8(bytes1(input[13])),
                     f1,
                     f2,
                     f3,
                     f4);
    }

    /* Model Data Storage */

    function _uploadModels (uint48 count, bytes memory data) internal {
        ItemStorage.upload(ModelData, count, data);
    }

    function _getModel (uint id) internal view returns (Model memory) {
        return unpackModel(ItemStorage.bget(ModelData, id));
    }

    /* Palettes Data Storage */

    function _uploadPalettes (uint48 count, bytes memory data) internal {
        ItemStorage.upload(PaletteData, count, data);
    }

    function _getPalette (uint id) internal view returns (bytes memory) {
        bytes memory loaded = ItemStorage.bget(PaletteData, id);
        bytes memory palette = new bytes(96);
        for (uint i = 0; i < loaded.length; i++) {
            palette[i] = loaded[i];
        }
        return palette;
    }

    /* Assemble Images */

    uint8 constant MCS = 5;

    function _staticGIF (Model memory m, bytes memory palette) internal pure returns (string memory) {
        bytes memory gif = GIF32.assembleStatic(m.width, m.height, true,
                                                GIF32.frame(0, 0, m.width, m.height, MCS, m.f1),
                                                MCS, palette);

        return string(abi.encodePacked("data:image/gif;base64,",Base64.encode(gif)));

    }

    function _animatedGIF (Model memory m, bytes memory palette) internal pure returns (string memory) {
        bytes memory framedata = abi.encodePacked(
                                                  abi.encodePacked(
                                                                   GIF32.gce10x(false, m.aniDelay1, 0),
                                                                   GIF32.frame(0, 0, m.width, m.height, MCS, m.f1)),

                                                  GIF32.gce10x(true, 0, 0),
                                                  GIF32.frame(m.aniX, m.aniY, m.aniWidth, m.aniHeight, MCS, m.f2),

                                                  GIF32.gce10x(true, m.aniDelay2, 0),
                                                  GIF32.frame(m.aniX, m.aniY, m.aniWidth, m.aniHeight, MCS, m.f3),

                                                  GIF32.gce10x(true, m.aniDelay3, 0),
                                                  GIF32.frame(m.aniX, m.aniY, m.aniWidth, m.aniHeight, MCS, m.f4));


        bytes memory gif = GIF32.assembleAnimated(m.width, m.height, framedata, MCS, palette);

        return string(abi.encodePacked("data:image/gif;base64,",Base64.encode(gif)));

    }

}