// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./Utils.sol";

library TypeBlocksArt {

    bytes public constant ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    uint256 internal constant XSTART = 213;
    uint256 internal constant YSTART = 126;
    uint256 internal constant SPACING = 40;

    function ALPHABETPLOT(bytes1 letter) internal pure returns (uint8[20] memory) {
        if(letter == 0x41) {
            return [ 2, 3, 4, 6, 10, 11, 15, 16, 20, 21, 22, 23, 24, 25, 26, 30, 31, 35, 0, 0 ];
        } else if(letter == 0x42) {
            return [ 1, 2, 3, 4, 6, 10, 11, 15, 16, 17, 18, 19, 21, 25, 26, 30, 31, 32, 33, 34 ];
        } else if(letter == 0x43) {
            return [ 2, 3, 4, 6, 10, 11, 16, 21, 26, 30, 32, 33, 34, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x44) {
            return [ 1, 2, 3, 4, 6, 10, 11, 15, 16, 20, 21, 25, 26, 30, 31, 32, 33, 34, 0, 0 ];
        } else if(letter == 0x45) {
            return [ 1, 2, 3, 4, 5, 6, 11, 16, 17, 18, 19, 21, 26, 31, 32, 33, 34, 35, 0, 0 ];
        } else if(letter == 0x46) {
            return [ 1, 2, 3, 4, 5, 6, 11, 16, 17, 18, 19, 21, 26, 31, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x47) {
            return [ 2, 3, 4, 6, 10, 11, 16, 21, 24, 25, 26, 30, 32, 33, 34, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x48) {
            return [ 1, 5, 6, 10, 11, 15, 16, 17, 18, 19, 20, 21, 25, 26, 30, 31, 35, 0, 0, 0 ];
        } else if(letter == 0x49) {
            return [ 2, 3, 4, 8, 13, 18, 23, 28, 32, 33, 34, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x4A) {
            return [ 2, 3, 4, 5, 9, 14, 19, 24, 26, 29, 32, 33, 0, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x4B) {
            return [ 1, 5, 6, 9, 11, 13, 16, 17, 21, 23, 26, 29, 31, 35, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x4C) {
            return [ 1, 6, 11, 16, 21, 26, 31, 32, 33, 34, 35, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x4D) {
            return [ 1, 5, 6, 7, 9, 10, 11, 13, 15, 16, 20, 21, 25, 26, 30, 31, 35, 0, 0, 0 ];
        } else if(letter == 0x4E) {
            return [ 1, 5, 6, 7, 10, 11, 13, 15, 16, 19, 20, 21, 25, 26, 30, 31, 35, 0, 0, 0 ];
        } else if(letter == 0x4F) {
            return [ 2, 3, 4, 6, 10, 11, 15, 16, 20, 21, 25, 26, 30, 32, 33, 34, 0, 0, 0, 0 ];
        } else if(letter == 0x50) {
            return [ 1, 2, 3, 4, 6, 10, 11, 15, 16, 17, 18, 19, 21, 26, 31, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x51) {
            return [ 2, 3, 4, 6, 10, 11, 15, 16, 20, 21, 23, 25, 26, 29, 30, 32, 33, 34, 35, 0 ];
        } else if(letter == 0x52) {
            return [ 1, 2, 3, 4, 6, 10, 11, 15, 16, 17, 18, 19, 21, 23, 26, 29, 31, 35, 0, 0 ];
        } else if(letter == 0x53) {
            return [ 2, 3, 4, 6, 10, 11, 17, 18, 19, 25, 26, 30, 32, 33, 34, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x54) {
            return [ 1, 2, 3, 4, 5, 8, 13, 18, 23, 28, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x55) {
            return [ 1, 5, 6, 10, 11, 15, 16, 20, 21, 25, 26, 30, 32, 33, 34, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x56) {
            return [ 1, 5, 6, 10, 11, 15, 16, 20, 21, 25, 27, 29, 33, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x57) {
            return [ 1, 5, 6, 10, 11, 15, 16, 20, 21, 23, 25, 26, 28, 30, 32, 34, 0, 0, 0, 0 ];
        } else if(letter == 0x58) {
            return [ 1, 5, 6, 10, 11, 15, 17, 18, 19, 21, 25, 26, 30, 31, 35, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x59) {
            return [ 1, 5, 6, 10, 11, 15, 17, 18, 19, 23, 28, 33, 0, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x5A) {
            return [ 1, 2, 3, 4, 5, 10, 14, 18, 22, 26, 31, 32, 33, 34, 35, 0, 0, 0, 0, 0 ];
        } else {
            return [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
        }
    }

    function getLetter(uint256 tokenId, uint256 min, uint256 max) internal view returns (bytes1[] memory) {
        uint256 range = max - min + 1;
        uint256 length = 1;
        if(range > 1) {
            length = Utils.getRandom(tokenId, range) + min;
        }

        bytes1[] memory letters = new bytes1[](length);
        
        for (uint256 i; i < length; i++) {
            uint256 alphabetIndex = Utils.getRandom(i + length + tokenId, 26);

            letters[i] = ALPHABET[alphabetIndex];
        }

        return letters;
    }

    function generateSVG(bytes1[] memory letters, string memory color) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<svg ',
                'viewBox="0 0 300 300" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg" ',
                'style="width:100%;background:#000;"',
            '>',
                '<rect width="300" height="300" fill="#000"/>',
                generateBlocks(letters, color),
            '</svg>'
        );
    }

    function generateBlocks(bytes1[] memory letters, string memory color) internal pure returns (bytes memory blocks) {
        for (uint256 i; i < 5; i++) {
            blocks = abi.encodePacked(
                blocks,
                '<g>',
                generateBlock(i, letters, color),
                '</g>'
            );
        }

        return blocks;
    }
    
    function generateBlock(uint256 number, bytes1[] memory letters, string memory color) internal pure returns (bytes memory typeBlock) {
        uint256 xStart = XSTART - number * SPACING;
        uint256 yStart = YSTART;
        string memory opacity = "0.09";
        uint256 count = 1;
        bytes1 letter;

        if(letters.length > 0 && number < letters.length ) {
            letter = letters[letters.length - 1 - number];
        }
        
        for (uint256 i; i < 7; i++) {
            for (uint256 j; j < 5; j++) {
                uint256 cx = xStart + (j * 7);
                uint256 cy = yStart + (i * 7);
                uint8[20] memory plot = ALPHABETPLOT(letter);
                
                for (uint256 k; k < plot.length; k++) {
                    opacity = "0.09";
                    if(0 == plot[k]) {
                        break;
                    } else if(count == plot[k]) {
                        opacity = "1";
                        break;
                    }
                }
                
                typeBlock = abi.encodePacked(
                    typeBlock,
                    '<rect x="', StringsUpgradeable.toString(cx), '" y="', StringsUpgradeable.toString(cy), '" fill="', color ,'" fill-opacity="', opacity ,'" width="6" height="6" rx=".69" ry=".69"/>'
                );
                unchecked { count++; }
            }
        }

        return typeBlock;
    }
}