// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/ISVG.sol";

error RatioInvalid();

/// @title SVG image library
library SVG {

    using Strings for uint256;

    /// Returns a Color that is brightened by the provided percentage
    /// @dev Any color component that is 0 will be treated as if it is 1. Also does not modify alpha
    function brightenColor(ISVG.Color memory source, uint32 percentage) internal pure returns (ISVG.Color memory color) {
        color.red = _brightenComponent(source.red, percentage);
        color.green = _brightenComponent(source.green, percentage);
        color.blue = _brightenComponent(source.blue, percentage);
        color.alpha = source.alpha;
    }

    /// Returns a mixed Color by balancing the ratio of `color1` over `color2`, with a total percentage (for overmixing and undermixing outside the source bounds)
    /// @dev Reverts with `RatioInvalid()` if `ratioPercentage` is > 100
    function mixColors(ISVG.Color memory color1, ISVG.Color memory color2, uint32 ratioPercentage, uint32 totalPercentage) internal pure returns (ISVG.Color memory color) {
        if (ratioPercentage > 100) revert RatioInvalid();
        color.red = _mixComponents(color1.red, color2.red, ratioPercentage, totalPercentage);
        color.green = _mixComponents(color1.green, color2.green, ratioPercentage, totalPercentage);
        color.blue = _mixComponents(color1.blue, color2.blue, ratioPercentage, totalPercentage);
        color.alpha = _mixComponents(color1.alpha, color2.alpha, ratioPercentage, totalPercentage);
    }

    /// Returns a proportionally-randomized Color between the floor and ceiling colors using a random Color seed
    /// @dev This algorithm does not support floor rgb values matching ceiling rgb values (ceiling must be at least +1 higher for each component)
    function randomizeColors(ISVG.Color memory floor, ISVG.Color memory ceiling, ISVG.Color memory random) internal pure returns (ISVG.Color memory color) {
        uint16 percent = (uint16(random.red) + uint16(random.green) + uint16(random.blue)) % 101; // Range is from 0-100
        color.red = _randomizeComponent(floor.red, ceiling.red, random.red, percent);
        color.green = _randomizeComponent(floor.green, ceiling.green, random.green, percent);
        color.blue = _randomizeComponent(floor.blue, ceiling.blue, random.blue, percent);
        color.alpha = 0xFF;
    }

    /// Returns an RGB string suitable for SVG based on the supplied Color and ColorType
    /// @dev includes necessary leading space for all types _except_ None
    function svgColorWithType(ISVG.Color memory color, ISVG.ColorType colorType) internal pure returns (string memory) {
        require(uint(colorType) < 3, "Invalid colorType");
        if (colorType == ISVG.ColorType.Fill) return string(abi.encodePacked(" fill='rgb(", _rawColor(color), ")'"));
        if (colorType == ISVG.ColorType.Stroke) return string(abi.encodePacked(" stroke='rgb(", _rawColor(color), ")'"));
        return string(abi.encodePacked("rgb(", _rawColor(color), ")")); // Fallback to None
    }
    
    /// Returns the opening of an SVG tag based on the supplied width and height
    function svgOpen(uint256 width, uint256 height) internal pure returns (string memory) {
        return string(abi.encodePacked("<svg viewBox='0 0 ", width.toString(), " ", height.toString(), "' xmlns='http://www.w3.org/2000/svg' version='1.1'>"));
    }

    function _brightenComponent(uint8 component, uint32 percentage) private pure returns (uint8 result) {
        uint32 brightenedComponent = (component == 0 ? 1 : component) * (percentage + 100) / 100;
        if (brightenedComponent > 0xFF) {
            result = 0xFF; // Clamp to 8 bits
        } else {
            result = uint8(brightenedComponent);
        }
    }

    function _mixComponents(uint8 component1, uint8 component2, uint32 ratioPercentage, uint32 totalPercentage) private pure returns (uint8 component) {
        uint32 mixedComponent = (uint32(component1) * ratioPercentage + uint32(component2) * (100 - ratioPercentage)) * totalPercentage / 10000;
        if (mixedComponent > 0xFF) {
            component = 0xFF; // Clamp to 8 bits
        } else {
            component = uint8(mixedComponent);
        }
    }

    function _randomizeComponent(uint8 floor, uint8 ceiling, uint8 random, uint16 percent) private pure returns (uint8 component) {
        component = floor + uint8(uint16(ceiling - (random & 0x01) - floor) * percent / uint16(100));
    }

    function _rawColor(ISVG.Color memory color) private pure returns (string memory) {
        return string(abi.encodePacked(uint256(color.red).toString(), ",", uint256(color.green).toString(), ",", uint256(color.blue).toString()));
    }
}