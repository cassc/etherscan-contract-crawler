// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                          //
//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  //
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. | //
// | |     _  _     | || | ____    ____ | || |     ____     | || |  _______     | || |  _________   | || |     _  _     | | //
// | |    | || |    | || ||_   \  /   _|| || |   .'    `.   | || | |_   __ \    | || | |_   ___  |  | || |    | || |    | | //
// | |    \_|\_|    | || |  |   \/   |  | || |  /  .--.  \  | || |   | |__) |   | || |   | |_  \_|  | || |    \_|\_|    | | //
// | |              | || |  | |\  /| |  | || |  | |    | |  | || |   |  __ /    | || |   |  _|  _   | || |              | | //
// | |              | || | _| |_\/_| |_ | || |  \  `--'  /  | || |  _| |  \ \_  | || |  _| |___/ |  | || |              | | //
// | |              | || ||_____||_____|| || |   `.____.'   | || | |____| |___| | || | |_________|  | || |              | | //
// | |              | || |              | || |              | || |              | || |              | || |              | | //
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' | //
//  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  //
//                                          .----------------.  .----------------.                                          //
//                                         | .--------------. || .--------------. |                                         //
//                                         | |     ____     | || |  _______     | |                                         //
//                                         | |   .'    `.   | || | |_   __ \    | |                                         //
//                                         | |  /  .--.  \  | || |   | |__) |   | |                                         //
//                                         | |  | |    | |  | || |   |  __ /    | |                                         //
//                                         | |  \  `--'  /  | || |  _| |  \ \_  | |                                         //
//                                         | |   `.____.'   | || | |____| |___| | |                                         //
//                                         | |              | || |              | |                                         //
//                                         | '--------------' || '--------------' |                                         //
//                                          '----------------'  '----------------'                                          //
//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  .----------------.  //
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. || .--------------. | //
// | |     _  _     | || |   _____      | || |  _________   | || |    _______   | || |    _______   | || |     _  _     | | //
// | |    | || |    | || |  |_   _|     | || | |_   ___  |  | || |   /  ___  |  | || |   /  ___  |  | || |    | || |    | | //
// | |    \_|\_|    | || |    | |       | || |   | |_  \_|  | || |  |  (__ \_|  | || |  |  (__ \_|  | || |    \_|\_|    | | //
// | |              | || |    | |   _   | || |   |  _|  _   | || |   '.___`-.   | || |   '.___`-.   | || |              | | //
// | |              | || |   _| |__/ |  | || |  _| |___/ |  | || |  |`\____) |  | || |  |`\____) |  | || |              | | //
// | |              | || |  |________|  | || | |_________|  | || |  |_______.'  | || |  |_______.'  | || |              | | //
// | |              | || |              | || |              | || |              | || |              | || |              | | //
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' || '--------------' | //
//  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  '----------------'  //
//                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
library MoreOrLessArt {

    using Strings for uint256;
    using Strings for uint8;
    using Strings for uint16;

    struct Art {
        uint8 numRects;
        uint8 numCircles;
        uint8 numTriangles;
        uint8 numLines;
        uint8 whichShape;
        uint48 randomTimestamp;
        uint128 randomDifficulty;
        uint256 randomSeed;
    }

    string internal constant _imageFooter = "</svg>";

    function getRectanglePalette() internal pure returns(string[5] memory) {
      return ['%23ece0d1', '%23dbc1ac', '%23967259', '%23634832', '%2338220f'];
    }

    function getCirclePalette() internal pure returns(string[5] memory) {
      return ['%230F2A38', '%231D3C43', '%232A4930', '%23132F13', '%23092409'];
    }

    function getLinePalette() internal pure returns(string[5] memory) {
      return ['%23b3e7dc', '%23a6b401', '%23eff67b', '%23d50102', '%236c0102'];
    }

    function getTrianglePalette() internal pure returns(string[5] memory) {
      return ['%237c7b89', '%23f1e4de', '%23f4d75e', '%23e9723d', '%230b7fab'];
    }

    function getDBochmanPalette() internal pure returns(string[5] memory) {
      return ['%23000000', '%233d3d3d', '%23848484', '%23bbbbbb', '%23ffffff'];
    }

    function getColorPalette(uint256 seed, Art memory artData) private pure returns(string[5] memory) {
        uint16 r = seededRandom(0, 3, seed, artData);
        if (r == 0) {
            return getCirclePalette();
        } else if (r == 1) {
            return getTrianglePalette();
        } else if (r == 2) {
            return getRectanglePalette();
        } else {
            return getDBochmanPalette();
        }
    }

    function random(uint128 difficulty, uint48 timestamp, uint seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(difficulty, timestamp, seed)));
    }

    function seededRandom(uint low, uint high, uint256 seed, Art memory artData) internal pure returns (uint16) {
        uint seedR = uint(uint256(keccak256(abi.encodePacked(seed, random(artData.randomDifficulty, artData.randomTimestamp, artData.randomSeed)))));
        uint randomnumber = seedR % high;
        randomnumber = randomnumber + low;
        return uint16(randomnumber);
    }

    function _wrapTrait(string memory trait, string memory value) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    function _generateHeader(uint256 seed, Art memory artData) internal pure returns (string memory) {
        string memory header = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' id='moreorless' width='1000' height='1000' viewBox='0 0 1000 1000' style='background-color:";
        string memory color = getColorPalette(seed, artData)[seededRandom(0, 5, seed, artData)];
        return string(abi.encodePacked(
            header,
            color,
            "'>"
        ));
    }

    function _generateCircles(Art memory artData) internal pure returns (string memory) {
        string memory circles = '';
        string[5] memory colorPalette = getColorPalette(artData.randomSeed, artData);
        for (uint i = 0; i < artData.numCircles; i++) {
            circles = string(abi.encodePacked(
                circles,
                "<ellipse cx='",
                seededRandom(0, 1000, artData.randomSeed + i, artData).toString(),
                "' cy='",
                seededRandom(0, 1000, artData.randomSeed - i, artData).toString(),
                "' rx='",
                seededRandom(0, 100, artData.randomSeed + i - 1, artData).toString(),
                "' ry='",
                seededRandom(0, 100, artData.randomSeed - i + 1, artData).toString(),
                "'",
                " fill='",
                colorPalette[seededRandom(0, 5, artData.randomSeed + i, artData)],
                "'",
            "/>"));
        }

        return circles;
    }

    function _generateSLines(uint256 seed, Art memory artData) internal pure returns (string memory) {
      return string(abi.encodePacked(
        " S",
        seededRandom(0, 1000, seed + 1, artData).toString(),
        " ",
        seededRandom(0, 1000, seed + 2, artData).toString(),
        " ",
        seededRandom(0, 1000, seed + 3, artData).toString(),
        " ",
        seededRandom(0, 1000, seed + 4, artData).toString()
      ));
    }

    function _generateLines(Art memory artData) internal pure returns (string memory) {
        string memory lines = '';
        string[5] memory colorPalette = getColorPalette(artData.randomSeed, artData);
        for (uint i = 0; i < artData.numLines; i++) {
            lines = string(abi.encodePacked(
                lines,
                "<path style='fill:none; stroke:",
                colorPalette[seededRandom(0, 5, i * i, artData)],
                "; stroke-width: 10px;' d='M",
                seededRandom(0, 400, i * i + 2, artData).toString(),
                " ",
                seededRandom(0, 400, i * i + 3, artData).toString(),
                _generateSLines(artData.randomSeed + i, artData),
                _generateSLines(artData.randomSeed - i, artData),
                " Z'",
            "/>"));
        }

        return lines;
    }

    function getTrianglePoints(uint256 seed, Art memory artData) private pure returns (string memory) {
        return string(abi.encodePacked(
            seededRandom(0, 1000, seed + 1, artData).toString(),
            ",",
            seededRandom(0, 1000, seed + 2, artData).toString(),
            " ",
            seededRandom(0, 1000, seed + 3, artData).toString(),
            ",",
            seededRandom(0, 1000, seed + 4, artData).toString(),
            " ",
            seededRandom(0, 1000, seed + 5, artData).toString(),
            ",",
            seededRandom(0, 1000, seed + 6, artData).toString(),
            "'"
      ));
    }

    function _generateTriangles(Art memory artData) internal pure returns (string memory) {
        string memory triangles = '';
        string[5] memory colorPalette = getColorPalette(artData.randomSeed, artData);
        for (uint i = 0; i < artData.numTriangles; i++) {
            triangles = string(abi.encodePacked(
                triangles,
                "<polygon points='",
                getTrianglePoints(artData.randomSeed + i, artData),
                " fill='",
                colorPalette[seededRandom(0, 5, artData.randomSeed - i, artData)],
                "'",
            "/>"));
        }

        return triangles;
    }

    function _generateRectangles(Art memory artData) internal pure returns (string memory) {
        string memory rectangles = '';
        string[5] memory colorPalette = getColorPalette(artData.randomSeed, artData);
        for (uint i = 0; i < artData.numRects; i++) {
            rectangles = string(abi.encodePacked(
                rectangles,
                "<rect width='",
                seededRandom(0, 400, artData.randomSeed + i, artData).toString(),
                "' height='",
                seededRandom(0, 400, artData.randomSeed - i, artData).toString(),
                "' x='",
                seededRandom(0, 1000, artData.randomSeed - 1 - i, artData).toString(),
                "' y='",
                seededRandom(0, 1000, artData.randomSeed + 1 + i, artData).toString(),
                "'",
                " fill='",
                colorPalette[seededRandom(0, 5, artData.randomSeed + i, artData)],
                "'",
            "/>"));
        }

        return rectangles;
    }
}