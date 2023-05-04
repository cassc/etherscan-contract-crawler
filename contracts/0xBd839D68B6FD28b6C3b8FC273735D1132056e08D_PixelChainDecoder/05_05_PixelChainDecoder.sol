// SPDX-License-Identifier: MIT

/*

............................................................
............................................................
............................................................
........',;;,,;,;,;;,,,;,,,,,,,,,;;;;;;;,,,;,,;;,;,.........
........'::,;cccccccccccccccccccccccccccccccccc;,:;. .......
........':;.,ccccccccccccccccccccccccccccc::ccc,.;;. .......
........':;.,:,..............................,:,.;;. .......
........':;.,:.  ............................,:,.;;. .......
........':;.,:. .............................,:,.;;. .......
........':;.,:. .............................;:,.;;. .......
........':;.,:. .............................;:,.;;. .......
.....',;:l:';c'.........',;;,'''''''........':o:,::...'.....
...',,cddl:;;;;,......',;cdoc:;;;;;,......',;oxoc:;;;;,.....
..'::. .........co;.';:;..  ..   ..'ll,.';:,..  ...   .:,  .
..'::. .':,.':;;dOo;;;:;..  ......':kOl;;;;,.   .;;. .,c,  .
...',..,;c:;:c;.',.  .',...',,;,,,'.,'.  .''...',:c'.,,,.  .
......,,,,,,,,,'........',,,,,,,,,,'........',,,,,,,,,..  ..
......  ......  .........          ............. ..   ......
........':;.,:. .............................;:,.;;. .......
........':;.,:. .............................;:,.;;. .......
........':;.,:. .............................;:,.;;. .......
........':;.,:. .............................;:,.;;. .......
........':;.,:' .............................;:,.;;. .......
........':;.,c:;;;::;::::::::::::::::::::;::::c,.;;. .......
........':;',cccccccc:cccccccccc::::::::cc:cccc,';;. .......
........';;;;:;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;,. .......
..................................................   .......
............................................................
............................................................
............................................................

by patrick piemonte for the PixelChain team

*/

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPixelChain {

    struct PixelChain {
        string name;
        bytes data;
        bytes palette;
        address author;
        uint256 date;
    }

    function pixelChains(uint256 index) external view returns (PixelChain memory);
}


contract PixelChainDecoder is Ownable {

    struct Color {
        uint8 r;
        uint8 g;
        uint8 b;
    }

    struct Cursor {
        uint256 x;
        uint256 y;
    }

    IPixelChain public _pxc = IPixelChain(0xbc0E164eE423B7800e355b012c06446e28b1a29d);

    function setPixelChainContract(address pxcAdress) public onlyOwner {
        _pxc = IPixelChain(pxcAdress);
    }

    function uintToHexDigit(uint256 value) internal pure returns (bytes1) {
        if (value < 10) {
            return bytes1(uint8(value) + uint8(bytes1('0')));
        } else {
            return bytes1(uint8(value - 10) + uint8(bytes1('a')));
        }
    }

    function uintToStr(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint8 r, uint8 g, uint8 b) internal pure returns (string memory) {
        bytes memory hexString = new bytes(6);
        hexString[0] = toHexChar(r >> 4);
        hexString[1] = toHexChar(r & 0x0f);
        hexString[2] = toHexChar(g >> 4);
        hexString[3] = toHexChar(g & 0x0f);
        hexString[4] = toHexChar(b >> 4);
        hexString[5] = toHexChar(b & 0x0f);
        return string(hexString);
    }

    function toHexChar(uint8 value) internal pure returns (bytes1) {
        if (value < 10) {
            return bytes1(uint8(48 + value));
        } else {
            return bytes1(uint8(87 + value));
        }
    }

    function paletteToColorRGBA(bytes memory palette) internal pure returns (Color[] memory) {
        Color[] memory colors = new Color[](palette.length / 3);
        uint256 colorIndex = 0;

        for (uint256 i = 0; i < palette.length; i += 3) {
            uint8 r = uint8(palette[i]);
            uint8 g = uint8(palette[i + 1]);
            uint8 b = uint8(palette[i + 2]);

            Color memory color = Color(r, g, b); // 255 alpha dropped for simplicity

            colors[colorIndex] = color;
            colorIndex++;
        }

        return colors;
    }

    function generateSvgImage(bytes memory imgData, bytes memory palette)
        public
        pure
        returns (string memory)
    {
        string memory svgImage = string(abi.encodePacked(
            '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 32 32">'
        ));

        Color[] memory colors = paletteToColorRGBA(palette);

        Cursor memory cursor = Cursor(0, 0);
        for (uint256 i = 0; i < imgData.length; i++) {
            Color memory color = colors[uint8(imgData[i])];
            string memory hexColor = toHexString(color.r, color.g, color.b);
            svgImage = string(abi.encodePacked(
                svgImage,
                '<rect x="', uintToStr(cursor.x), '" y="', uintToStr(cursor.y), '" width="1.5" height="1.5" fill="#', hexColor, '"/>'
            ));
            cursor.x++;
            if (cursor.x >= 32) {
                cursor.x = 0;
                cursor.y++;
            }
        }

        svgImage = string(abi.encodePacked(
            svgImage,
            '</svg>'
        ));

        return svgImage;
    }

    function generatePixelChainImage(uint256 tokenId)
        external
        view
        returns (string memory) {
        require(tokenId < 2804); // v1 token limit
        IPixelChain.PixelChain memory pxc = _pxc.pixelChains(tokenId);

        string memory svgImage = generateSvgImage(pxc.data, pxc.palette);
        return  svgImage;
    }
    
}