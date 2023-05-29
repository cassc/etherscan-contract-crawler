// SPDX-License-Identifier: GPL-3.0
/// @title Jackson2SVGs
/// @dev this contract contains all the code to convert
/// mints (as bytes32) into SVG snippets.

pragma solidity ^0.8.19;

import "./ArtParams.sol";
import "./Mint.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Jackson2SVGs {
    using Mint for bytes32;
    using Strings for uint256;
    
    /// SHAPES ******************************************

    function getRectangleSVG(bytes32 mint) internal pure returns (bytes memory rectangleSVG) {
        rectangleSVG = abi.encodePacked(
            "<rect x='", intToString(byteToInt(mint[1], PAINTABLE_MIN_X, PAINTABLE_MIN_X * -1)),
            "' y='", intToString(byteToInt(mint[2], PAINTABLE_MIN_Y, PAINTABLE_MIN_Y * -1)),
            "' width='", intToString(byteToInt(mint[3], RECTANGLE_MIN_WIDTH, PAINTABLE_MIN_X * -2)),
            "' height='", intToString(byteToInt(mint[4], RECTANGLE_MIN_WIDTH, PAINTABLE_MIN_Y * -2)),
            "' fill='", extractColor(mint, 5),
            "' opacity='0.", intToString(byteToInt(mint[8], MIN_OPACITY, MAX_OPACITY)),
            "' />");
    }

    function getCircleSVG(bytes32 mint) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "<circle cx='", intToString(byteToInt(mint[1], PAINTABLE_MIN_X, PAINTABLE_MIN_X * -1)),
            "' cy='", intToString(byteToInt(mint[2], PAINTABLE_MIN_Y, PAINTABLE_MIN_Y * -1)),
            "' r='", intToString(byteToInt(mint[3], CIRCLE_MIN_RADIUS, CIRCLE_MAX_RADIUS)),
            "' fill='", extractColor(mint, 4),
            "' opacity='0.", intToString(byteToInt(mint[7], MIN_OPACITY, MAX_OPACITY)),
            "' />");
    }

    /// EFFECTS ******************************************

    function getRotateSVG(bytes32 mint) internal pure returns (bytes memory) {
        return abi.encodePacked('<g transform="rotate(', intToString(byteToInt(mint[1], -180, 180)), ')" ><g>');
    }

    function getQuadSVG(bytes32 mint, uint id) internal pure returns (bytes memory) {
        int a = byteToInt(mint[1], QUAD_MIN_AMOUNT, QUAD_MAX_AMOUNT);
        string memory amount = intToString(a);
        string memory nAmount = intToString(a * -1);
        
        return abi.encodePacked(
            '<filter id="quad', id.toString(),
            '" x="-140" y="-190" width="280" height="380">',
            '<feOffset in="SourceGraphic" x="-140" y="-190" width="140" height="190" dx="', nAmount, '" dy="', nAmount, '" result="o1"/>',
            '<feOffset in="SourceGraphic" x="0" y="-190" width="140" height="190" dx="', amount, '" dy="',nAmount,'" result="o2"/>',
            '<feOffset in="SourceGraphic" x="-140" y="0" width="140" height="190" dx="', nAmount, '" dy="', amount,'" result="o3"/>',
            '<feOffset in="SourceGraphic" x="0" y="0" width="140" height="190" dx="', amount, '" dy="', amount, '" result="o4"/>',
            '<feMerge><feMergeNode in="o1"/><feMergeNode in="o2" /><feMergeNode in="o3"/><feMergeNode in="o4"/></feMerge>',
            '</filter><g filter="url(#quad', id.toString(), ')"><g>'
        );
    }

    function getShearSVG(bytes32 mint, uint id) internal pure returns (bytes memory) {
        int amount = byteToInt(mint[1], SHEAR_MIN_AMOUNT, SHEAR_MAX_AMOUNT);
        int slices = byteToInt(mint[2], SHEAR_MIN_SLICES, SHEAR_MAX_SLICES);

        bytes memory offsetsSVG = '';
        int sliceWidth = 280 / slices;
        for (int i = 0; i < slices; i++) {
            int dy = ((((i * 100) - ((slices * 100) - 100)/2) / slices) * amount) / 100;

            offsetsSVG = abi.encodePacked(offsetsSVG,
                '<feOffset in="SourceGraphic" x="',
                intToString(-140 + (sliceWidth * i)),
                '" y="-190" width="', intToString(sliceWidth), '" height="380" dy="',
                intToString(dy),
                '" result="d', intToString(i), '"/>');
        }

        bytes memory mergeSVG = '<feMerge>';
        for (uint i = 0; i < uint(slices); i++) {
            mergeSVG = abi.encodePacked(mergeSVG, '<feMergeNode in="d', i.toString(), '"/>');
        }
        mergeSVG = abi.encodePacked(mergeSVG, '</feMerge>');

        return abi.encodePacked(
            '<filter id="shear', id.toString(),
            '" x="-140" y="-190" width="280" height="380">',
            offsetsSVG,
            mergeSVG,
            '</filter><g filter="url(#shear', id.toString(), ')"><g>'
        );
    }

    function getWindowRectangleSVG(bytes32 mint, uint id) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "<mask id='maskr", id.toString(),
            "'><rect x='", intToString(byteToInt(mint[1], PAINTABLE_MIN_X, PAINTABLE_MIN_X * -1)),
            "' y='", intToString(byteToInt(mint[2], PAINTABLE_MIN_Y, PAINTABLE_MIN_Y * -1)),
            "' width='", intToString(byteToInt(mint[3], WINDOW_RECTANGLE_MIN_WIDTH, PAINTABLE_MIN_X * -2)),
            "' height='", intToString(byteToInt(mint[4], WINDOW_RECTANGLE_MIN_WIDTH, PAINTABLE_MIN_Y * -2)),
            "' fill='white'/></mask><g mask='url(#maskr", id.toString(), ")'><g>"
        );
    }

    function getWindowCircleSVG(bytes32 mint, uint id) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "<mask id='maskc", id.toString(),
            "'><circle cx='", intToString(byteToInt(mint[1], PAINTABLE_MIN_X, PAINTABLE_MIN_X * -1)),
            "' cy='", intToString(byteToInt(mint[2], PAINTABLE_MIN_Y, PAINTABLE_MIN_Y * -1)),
            "' r='", intToString(byteToInt(mint[3], WINDOW_CIRCLE_MIN_RADIUS, CIRCLE_MAX_RADIUS)),
            "' fill='white'/></mask><g mask='url(#maskc", id.toString(), ")'><g>"
        );
    }

    function getTileSVG(bytes32 mint, uint id) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "<filter id='tile", id.toString(), "' x='-140' y='-190' width='280' height='380'><feOffset dx='0' x='"
            , intToString(byteToInt(mint[1], PAINTABLE_MIN_X, PAINTABLE_MIN_X * -1)),
            "' y='", intToString(byteToInt(mint[2], PAINTABLE_MIN_Y, PAINTABLE_MIN_Y * -1)),
            "' width='", intToString(byteToInt(mint[3], WINDOW_RECTANGLE_MIN_WIDTH, PAINTABLE_MIN_X * -2)),
            "' height='", intToString(byteToInt(mint[4], WINDOW_RECTANGLE_MIN_WIDTH, PAINTABLE_MIN_Y * -2)),
            "' result='in'/><feTile in='in' x='-140' y='-190' width='280' height='380'/></filter><g filter='url(#tile", id.toString(), ")'><g>"
        );
    }

    function getScaleSVG(bytes32 mint) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "<g transform='scale(", toDecimal(byteToInt(mint[1], 50, 200)), " ", toDecimal(byteToInt(mint[2], 50, 200)), ")'><g>"
        );
    }

    function getItalicizeSVG(bytes32 mint) internal pure returns (bytes memory) {
        return abi.encodePacked("<g transform='skewX(", intToString(byteToInt(mint[1], -50, 50)), ")'><g>"
        );
    }

    /// UTILITY FUNCTIONS ********************************

    function intToString(int i) internal pure returns (string memory) {
        if (i >= 0) {
            return uint(i).toString();
        }
        else {
            return string(abi.encodePacked("-", uint(i * -1).toString()));
        }
    }

    // ONLY POSITIVE INTEGERS OUT OF 100
    function toDecimal(int i) internal pure returns (bytes memory) {
        int whole = (i / 100);
        int decimal = (i % 100);
        string memory point = decimal >= 10 ? "." : (decimal > 0 ? ".0" : ".00");
        return abi.encodePacked(intToString(whole), point, intToString(decimal));
    }

    function extractColor(bytes32 mint, uint index) internal pure returns (bytes memory) {
        return abi.encodePacked("rgb(",
                Strings.toString(uint8(mint[index])), ",",
                Strings.toString(uint8(mint[index + 1])), ",",
                Strings.toString(uint8(mint[index + 2])),
            ")");
    }

    function byteToInt(bytes1 _byte, int min, int max) internal pure returns (int theInt) {
        int percent = (int16(uint16(uint8(_byte)) * 100) / 255);
        int i = min + (percent * (max - min) / 100);
        return i;
    }
}