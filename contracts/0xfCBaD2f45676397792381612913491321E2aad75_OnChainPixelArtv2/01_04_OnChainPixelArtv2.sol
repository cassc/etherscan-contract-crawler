// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

import {OnChainPixelArtLibrary} from "./OnChainPixelArtLibrary.sol";
import {OnChainPixelArtLibraryv2} from "./OnChainPixelArtLibraryv2.sol";

pragma solidity ^0.8.0;

contract OnChainPixelArtv2 {
    function base64Encode(bytes memory data)
        public
        pure
        returns (string memory)
    {
        return OnChainPixelArtLibrary.base64Encode(data);
    }

    function toHexString(uint256 value) public pure returns (string memory) {
        return OnChainPixelArtLibrary.toHexString(value);
    }

    function toString(uint256 value) public pure returns (string memory) {
        return OnChainPixelArtLibrary.toString(value);
    }

    function getColorCompression(uint256 colorCount)
        internal
        pure
        returns (uint256 comp)
    {
        return OnChainPixelArtLibrary.getColorCompression(colorCount);
    }

    function getPixelCompression(uint256[] memory layers)
        internal
        pure
        returns (uint256 pixelCompression)
    {
        return OnChainPixelArtLibrary.getPixelCompression(layers);
    }

    function getColorCount(uint256[] memory layers)
        public
        pure
        returns (uint256 colorCount)
    {
        return OnChainPixelArtLibrary.getColorCount(layers);
    }

    function getStartingIndex(uint256[] memory layers)
        internal
        pure
        returns (uint256 startingIndex)
    {
        return OnChainPixelArtLibrary.getStartingIndex(layers);
    }

    function encodeColorArray(
        uint256[] memory colors,
        uint256 pixelCompression,
        uint256 colorCount
    ) public pure returns (uint256[] memory encoded) {
        return
            OnChainPixelArtLibrary.encodeColorArray(
                colors,
                pixelCompression,
                colorCount
            );
    }

    function composePalettes(
        uint256[] memory palette1,
        uint256[] memory palette2,
        uint256 colorCount1,
        uint256 colorCount2
    ) public pure returns (uint256[] memory composedPalette) {
        return
            OnChainPixelArtLibrary.composePalettes(
                palette1,
                palette2,
                colorCount1,
                colorCount2
            );
    }

    function composeLayer(
        uint256[] memory layer,
        uint256 colorOffset,
        uint256[] memory colors,
        uint256 totalPixels
    ) internal pure returns (uint256[] memory comp) {
        return
            OnChainPixelArtLibrary.composeLayer(
                layer,
                colorOffset,
                colors,
                totalPixels
            );
    }

    function composeLayers(
        uint256[] memory layer1,
        uint256[] memory layer2,
        uint256 totalPixels
    ) public pure returns (uint256[] memory comp) {
        return
            OnChainPixelArtLibrary.composeLayers(layer1, layer2, totalPixels);
    }

    function uri(string memory data)
        external
        pure
        returns (string memory encoded)
    {
        return OnChainPixelArtLibrary.uri(data);
    }

    function uriSvg(string memory data)
        external
        pure
        returns (string memory encoded)
    {
        return OnChainPixelArtLibrary.uriSvg(data);
    }

    function render(
        uint256[] memory canvas,
        uint256[] memory palette,
        uint256 xDim,
        uint256 yDim,
        string memory svgExtension,
        uint256 paddingX,
        uint256 paddingY
    ) external pure returns (string memory svg) {
        return
            OnChainPixelArtLibraryv2.render(
                canvas,
                palette,
                xDim,
                yDim,
                svgExtension,
                paddingX,
                paddingY
            );
    }
}