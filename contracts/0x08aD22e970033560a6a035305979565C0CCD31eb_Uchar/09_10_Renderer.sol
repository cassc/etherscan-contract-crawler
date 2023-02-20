/*

░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░                                                        ░░
░░    . . 1 . .    . . 1 . .    . . 1 . .    . . 1 . .    ░░
░░   . \  |  / .  . \  |  / .  . \  |  / .  . \  |  / .   ░░
░░   6  9 | 11 2  6  9 | 11 2  6  9 | 11 2  6  9 | 11 2   ░░
░░   .   \|/   .  .   \|/   .  .   \|/   .  .   \|/   .   ░░
░░    .7. 4 .8.    .7. 4 .8.    .7. 4 .8.    .7. 4 .8.    ░░
░░   .   /|\   .  .   /|\   .  .   /|\   .  .   /|\   .   ░░
░░   5 12 | 14 3  5 12 | 14 3  5 12 | 14 3  5 12 | 14 3   ░░
░░   . /  |  \ .  . /  |  \ .  . /  |  \ .  . /  |  \ .   ░░
░░    . . 4 . .    . . 4 . .    . . 4 . .    . . 4 . .    ░░
░░        a            b            c            d        ░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/ISegments.sol";
import "./Utilities.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

library renderer {
    function getBaseColorName(uint index) internal pure returns (string memory) {
        string[4] memory baseColorNames = ["White", "Red", "Green", "Blue"];
        return baseColorNames[index];
    }

    function getMetadata(ISegments segments, uint tokenId, string memory word, uint points, uint baseColor, bool burned) internal pure returns (string memory) {
        uint[3] memory rgbs = utils.getRgbs(tokenId, baseColor);
        string memory json;

        if (burned) {
            json = string(abi.encodePacked(
            '{"name": "UCHARS ',
            utils.uint2str(tokenId),
            ' [BURNED]", "description": "Letters are art, and we are artists.", "attributes":[{"trait_type": "Burned", "value": "Yes"}], "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(segments.renderSvg(word, rgbs))),
            '"}'
        ));
        } else {
            json = string(abi.encodePacked(
            '{"name": "UCHARS ',
            utils.uint2str(tokenId),
            '", "description": "Letters are art, and we are artists.", "attributes":[{"trait_type": "Points", "value": ', 
            utils.uint2str(points),
            '},{"trait_type": "Char", "value": "',
            word,
            '"},{"trait_type": "Length", "max_value": 8, "value": ',
            utils.uint2str(bytes(word).length),
            '},{"display_type": "number", "trait_type": "Mint Phase", "value": ',
            utils.uint2str(utils.getMintPhase(tokenId)),
            '},{"trait_type": "Burned", "value": "No"},{"trait_type": "Base Color", "value": "',
            getBaseColorName(baseColor),
            '"},{"trait_type": "Color", "value": "RGB(',
            utils.uint2str(rgbs[0]),
            ",",
            utils.uint2str(rgbs[1]),
            ",",
            utils.uint2str(rgbs[2]),
            ')"}], "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(segments.renderSvg(word, rgbs))),
            '"}'
        ));
        }

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));
    }
}