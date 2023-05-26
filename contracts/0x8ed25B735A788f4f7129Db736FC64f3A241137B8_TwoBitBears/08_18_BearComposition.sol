// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./IBearDetail.sol";

/// @title BearComposition
library BearComposition {

    using Strings for uint256;

    function fourIndexFromRandom(uint8 random) internal pure returns (uint256) {
        uint8 spread = random % 100;
        if (spread >= 46) {
            return 0; // 54% is Brown/Happy
        } else if (spread >= 16) {
            return 1; // 30% is Black/Hungry
        } else if (spread >= 1) {
            return 2; // 15% is Polar/Sleepy
        }
        return 3; // 1% is Panda/Grumpy
    }

    function colorBottomFromRandom(bytes memory source, uint256 indexRed, uint256 indexGreen, uint256 indexBlue, uint256 speciesIndex) internal pure returns (IBearDetail.Color memory) {
        return randomizeColors(
            _colorBottomFloorForSpecies(speciesIndex),
            _colorBottomCeilingForSpecies(speciesIndex),
            IBearDetail.Color(uint8(source[indexRed]), uint8(source[indexGreen]), uint8(source[indexBlue]))
        );
    }

    function colorTopFromRandom(bytes memory source, uint256 indexRed, uint256 indexGreen, uint256 indexBlue, uint256 speciesIndex) internal pure returns (IBearDetail.Color memory) {
        return randomizeColors(
            _colorTopFloorForSpecies(speciesIndex),
            _colorTopCeilingForSpecies(speciesIndex),
            IBearDetail.Color(uint8(source[indexRed]), uint8(source[indexGreen]), uint8(source[indexBlue]))
        );
    }

    function _colorBottomFloorForSpecies(uint256 index) private pure returns (IBearDetail.Color memory) {
        if (index == 0) { // Brown
            return IBearDetail.Color(64, 38, 14);
        } else if (index == 1) { // Black
            return IBearDetail.Color(34, 34, 37);
        } else if (index == 2) { // Polar
            return IBearDetail.Color(177, 182, 180);
        } else { // Panda
            return IBearDetail.Color(0, 0, 0);
        }
    }

    function _colorBottomCeilingForSpecies(uint256 index) private pure returns (IBearDetail.Color memory) {
        if (index == 0) { // Brown
            return IBearDetail.Color(119, 81, 45);
        } else if (index == 1) { // Black
            return IBearDetail.Color(72, 72, 77);
        } else if (index == 2) { // Polar
            return IBearDetail.Color(223, 231, 230);
        } else { // Panda
            return IBearDetail.Color(18, 18, 19);
        }
    }

    function _colorTopFloorForSpecies(uint256 index) private pure returns (IBearDetail.Color memory) {
        if (index == 0) { // Brown
            return IBearDetail.Color(141, 93, 51);
        } else if (index == 1) { // Black
            return IBearDetail.Color(56, 56, 64);
        } else if (index == 2) { // Polar
            return IBearDetail.Color(208, 229, 226);
        } else { // Panda
            return IBearDetail.Color(221, 221, 222);
        }
    }

    function _colorTopCeilingForSpecies(uint256 index) private pure returns (IBearDetail.Color memory) {
        if (index == 0) { // Brown
            return IBearDetail.Color(193, 162, 134);
        } else if (index == 1) { // Black
            return IBearDetail.Color(87, 92, 109);
        } else if (index == 2) { // Polar
            return IBearDetail.Color(235, 240, 239);
        } else { // Panda
            return IBearDetail.Color(226, 225, 232);
        }
    }
    
    function randomizeColors(IBearDetail.Color memory floor, IBearDetail.Color memory ceiling, IBearDetail.Color memory random) private pure returns (IBearDetail.Color memory color) {
        uint256 percent = (uint256(random.red) + uint256(random.green) + uint256(random.blue)) % 100;
        color.red = floor.red + uint8(uint256(ceiling.red + (random.red % 2) - floor.red) * percent / 100);
        color.green = floor.green + uint8(uint256(ceiling.green + (random.green % 2) - floor.green) * percent / 100);
        color.blue = floor.blue + uint8(uint256(ceiling.blue + (random.blue % 2) - floor.blue) * percent / 100);
    }

    function createSvg(IBearDetail.Detail memory detail) internal pure returns (bytes memory) {
        return abi.encodePacked(
            svgOpen(1080, 1080),
            "<path id='Head' d='M405 540 L675 540 675 270 405 270 Z' fill='",
            svgColor(detail.topColor),
            "'/><path id='Torso' d='M405 810 L675 810 675 540 405 540 Z' fill='",
            svgColor(detail.bottomColor),
            "'/></svg>"
        );
    }

    function svgColor(IBearDetail.Color memory color) internal pure returns (string memory) {
        return string(abi.encodePacked("rgb(", uint256(color.red).toString(), ",", uint256(color.green).toString(), ",", uint256(color.blue).toString(), ")"));
    }
    
    function svgOpen(uint256 width, uint256 height) private pure returns (string memory) {
        return string(abi.encodePacked("<svg viewBox='0 0 ", width.toString(), " ", height.toString(), "' xmlns='http://www.w3.org/2000/svg' version='1.1'>"));
    }
}