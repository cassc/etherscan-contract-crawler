// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ICubTraits.sol";
import "./SVG.sol";

/// @title CubComposition
library CubComposition {

    using Strings for uint256;

    /// Returns the bottom color of a Two Bit Bear using a random source of bytes and r/g/b indices into the array
    function colorBottomFromRandom(bytes memory source, uint256 indexRed, uint256 indexGreen, uint256 indexBlue, ICubTraits.CubSpeciesType species) internal pure returns (ISVG.Color memory) {
        return SVG.randomizeColors(
            _colorBottomFloorForSpecies(species),
            _colorBottomCeilingForSpecies(species),
            ISVG.Color(uint8(source[indexRed]), uint8(source[indexGreen]), uint8(source[indexBlue]), 0xFF)
        );
    }

    /// Returns the top color of a Two Bit Bear using a random source of bytes and r/g/b indices into the array
    function colorTopFromRandom(bytes memory source, uint256 indexRed, uint256 indexGreen, uint256 indexBlue, ICubTraits.CubSpeciesType species) internal pure returns (ISVG.Color memory) {
        return SVG.randomizeColors(
            _colorTopFloorForSpecies(species),
            _colorTopCeilingForSpecies(species),
            ISVG.Color(uint8(source[indexRed]), uint8(source[indexGreen]), uint8(source[indexBlue]), 0xFF)
        );
    }

    /// Mixes two input colors with random variations based on provided seed data and percentages
    function randomColorFromColors(ISVG.Color memory color1, ISVG.Color memory color2, bytes memory source, uint256 indexRatio, uint256 indexPercentage) internal pure returns (ISVG.Color memory color) {
        // ratioPercentage will range from 0-100 to lean towards color1 or color2 when mixing
        // totalPercentage will range from 97-103 to either undermix or overmix the parent colors
        color = SVG.mixColors(color1, color2, uint8(source[indexRatio]) % 101, 97 + (uint8(source[indexPercentage]) % 7));
        color.alpha = 0xFF; // Force the alpha to fully opaque, regardless of mixing
    }

    /// Creates the SVG for a TwoBitBear Cub based on its ICubDetail.Traits
    function createSvg(ICubTraits.TraitsV1 memory traits, uint256 adultAge) internal pure returns (bytes memory) {
        string memory transform = svgTransform(traits, adultAge);
        return abi.encodePacked(
            SVG.svgOpen(1080, 1080),
            _createPath(SVG.brightenColor(traits.topColor, 7), "Head", "M405 675 L540 675 540 540 405 540 Z", "M370 675 L570 675 570 540 370 560 Z", transform),
            _createPath(traits.topColor, "HeadShadow", "M540 675 L675 675 675 540 540 540 Z", "M570 675 L710 675 710 564 570 540 Z", transform),
            _createPath(SVG.brightenColor(traits.bottomColor, 7), "Torso", "M405 810 L540 810 540 675 405 675 Z", "M370 790 L570 810 570 675 370 675 Z", transform),
            _createPath(traits.bottomColor, "TorsoShadow", "M540 810 L675 810 675 675 540 675 Z", "M570 810 L710 786 710 675 570 675 Z", transform),
            "</svg>"
        );
    }

    function _createPath(ISVG.Color memory color, string memory name, string memory path1, string memory path2, string memory transform) private pure returns (bytes memory) {
        return abi.encodePacked(
            "<path id='", name, "' d='", path1, "'", SVG.svgColorWithType(color, ISVG.ColorType.Fill), transform, "><animate attributeName='d' values='", path1, ";", path2, "' begin='4s' dur='1s' fill='freeze'/></path>"
        );
    }

    /// Returns a value based on the spread of a random seed and provided percentages (last percentage is assumed if the sum of all elements do not add up to 100)
    function randomIndexFromPercentages(uint8 random, uint8[] memory percentages) internal pure returns (uint256) {
        uint256 spread = random % 100;
        uint256 remainingPercent = 100;
        for (uint256 i = 0; i < percentages.length; i++) {
            remainingPercent -= percentages[i];
            if (spread >= remainingPercent) {
                return i;
            }
        }
        return percentages.length;
    }

    /// Creates a `transform` attribute for a `path` element based on the age of the cub
    function svgTransform(ICubTraits.TraitsV1 memory traits, uint256 adultAge) internal pure returns (string memory) {
        (string memory yScale, string memory yTranslate) = _yTransforms(traits, adultAge);
        return string(abi.encodePacked(" transform='translate(0,", yTranslate, "),scale(1,", yScale, ")'"));
    }

    function toSvgColor(uint24 packedColor) internal pure returns (ISVG.Color memory color) {
        color.red = uint8(packedColor >> 16);
        color.green = uint8(packedColor >> 8);
        color.blue = uint8(packedColor);
        color.alpha = 0xFF;
    }

    function _colorBottomFloorForSpecies(ICubTraits.CubSpeciesType species) private pure returns (ISVG.Color memory) {
        if (species == ICubTraits.CubSpeciesType.Brown) {
            return toSvgColor(0x40260E);
        } else if (species == ICubTraits.CubSpeciesType.Black) {
            return toSvgColor(0x222225);
        } else if (species == ICubTraits.CubSpeciesType.Polar) {
            return toSvgColor(0xB1B6B4);
        } else { // Panda
            return toSvgColor(0x000000);
        }
    }

    function _colorBottomCeilingForSpecies(ICubTraits.CubSpeciesType species) private pure returns (ISVG.Color memory) {
        if (species == ICubTraits.CubSpeciesType.Brown) {
            return toSvgColor(0x77512D);
        } else if (species == ICubTraits.CubSpeciesType.Black) {
            return toSvgColor(0x48484D);
        } else if (species == ICubTraits.CubSpeciesType.Polar) {
            return toSvgColor(0xDFE7E6);
        } else { // Panda
            return toSvgColor(0x121213);
        }
    }

    function _colorTopFloorForSpecies(ICubTraits.CubSpeciesType species) private pure returns (ISVG.Color memory) {
        if (species == ICubTraits.CubSpeciesType.Brown) {
            return toSvgColor(0x8D5D33);
        } else if (species == ICubTraits.CubSpeciesType.Black) {
            return toSvgColor(0x383840);
        } else if (species == ICubTraits.CubSpeciesType.Polar) {
            return toSvgColor(0xD0E5E2);
        } else { // Panda
            return toSvgColor(0xDDDDDE);
        }
    }

    function _colorTopCeilingForSpecies(ICubTraits.CubSpeciesType species) private pure returns (ISVG.Color memory) {
        if (species == ICubTraits.CubSpeciesType.Brown) {
            return toSvgColor(0xC1A286);
        } else if (species == ICubTraits.CubSpeciesType.Black) {
            return toSvgColor(0x575C6D);
        } else if (species == ICubTraits.CubSpeciesType.Polar) {
            return toSvgColor(0xEBF0EF);
        } else { // Panda
            return toSvgColor(0xE2E1E8);
        }
    }

    function _yTransforms(ICubTraits.TraitsV1 memory traits, uint256 adultAge) private pure returns (string memory scale, string memory translate) {
        if (traits.age >= adultAge) {
            translate = "-810";
            scale = "2";
        } else if (traits.age > 0) {
            uint256 fraction = traits.age * 810 / adultAge;
            translate = fraction < 1 ? "-1" : string(abi.encodePacked("-", fraction.toString()));
            fraction = traits.age * 100 / adultAge;
            scale = string(abi.encodePacked(fraction < 10 ? "1.0" : "1.", fraction.toString()));
        } else {
            translate = "0";
            scale = "1";
        }
    }
}