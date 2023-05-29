// SPDX-License-Identifier: GPL-3.0
/// @title TheHours2Art.sol
/// @author Lawrence X Rogers
/// @dev this contract handles the assembly of mints into a TheHours SVG

pragma solidity ^0.8.19;
import "./Jackson2SVGs.sol";
import "./ArtParams.sol";
import "./Mint.sol";
import "hardhat/console.sol";
import "contracts/interfaces/ITheHours.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheHoursArt is Jackson2SVGs, ITheHoursArt {
    using Strings for uint256;
    using Strings for int256;
    using Mint for bytes32;

    uint8 constant MINT_TYPE_INDEX = 0;

    /// @notice generates an SVG from a list of mints, up to index @index
    function generateSVG(bytes32[] memory mints, uint256 index)
        external
        pure
        returns (bytes memory svg)
    {
        uint256 effectsTotal = countEffects(mints);
        bytes[] memory effectsQueue = new bytes[](effectsTotal);
        uint256 effectsIndex = 0;
        bytes memory bgColor = "nobackgroundspecified";

        for (uint256 i1 = index + 1; i1 > 0; i1--) {
            uint256 i = i1 - 1;
            bytes32 mint = mints[i];
            if (mint.isBackground() && bgColor.length == 21) {
                bgColor = extractColor(mint, 1);
            }
            else {
                if (mint.isBackground()) continue;
                else if (mint.isShape()) {
                    svg = bytes.concat(getShapeSVG(mint), svg);
                } else {
                    svg = bytes.concat("</g></g>", svg);
                    effectsQueue[effectsIndex++] = getEffectSVG(mint, i);
                }
            }
        }
        
        for (int256 i = int256(effectsIndex) - 1; i >= 0; i--) {
            svg = bytes.concat(effectsQueue[uint256(i)], svg);
        }
        
        if (bgColor.length == 21) { // length of "nobackgroundspecified"
            bgColor = "white";
        }
        return abi.encodePacked(svg_begin, bgColor, svg_begin_2, svg, svg_end);
    }

    /// @notice checks which type of shape the Mint is, and calls the corresponding function
    function getShapeSVG(bytes32 mint)
        internal
        pure
        returns (bytes memory shapeSVG)
    {
        if (mint.mintType() == MINT_TYPE_RECTANGLE) {
            return getRectangleSVG(mint);
        } else if (mint.mintType() == MINT_TYPE_CIRCLE) {
            return getCircleSVG(mint);
        }
    }

    /// @notice checks which type of Effect the Mint is, and calls the corresponding function
    function getEffectSVG(bytes32 mint, uint256 id)
        internal
        pure
        returns (bytes memory)
    {
        if (mint.mintType() == MINT_TYPE_ROTATE) return getRotateSVG(mint);    
        else if (mint.mintType() == MINT_TYPE_QUAD) return getQuadSVG(mint, id);
        else if (mint.mintType() == MINT_TYPE_SHEAR) return getShearSVG(mint, id);
        else if (mint.mintType() == MINT_TYPE_WINDOW_RECTANGLE) return getWindowRectangleSVG(mint, id);
        else if (mint.mintType() == MINT_TYPE_WINDOW_CIRCLE) return getWindowCircleSVG(mint, id);
        else if (mint.mintType() == MINT_TYPE_TILE) return getTileSVG(mint, id);
        else if (mint.mintType() == MINT_TYPE_SCALE) return getScaleSVG(mint);
        else if (mint.mintType() == MINT_TYPE_ITALICIZE) return getItalicizeSVG(mint);
        return "";
    }

    function countEffects(bytes32[] memory mints)
        internal
        pure
        returns (uint256 count)
    {
        for (uint256 i = 0; i < mints.length; i++) {
            if (mints[i].isEffect()) count++;
        }
    }
}