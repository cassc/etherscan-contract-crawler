// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../Base64.sol";
import "./ISVGWrapper.sol";

contract SVGWrapper is ISVGWrapper {
    bytes public constant SVG_URI_PREFIX = "data:image/svg+xml;base64,";

    function getWrappedImage(
        string memory imageUri,
        uint256 canonicalWidth,
        uint256 canonicalHeight
    ) public pure virtual returns (string memory imageDataUri) {
        string memory imageData = string(
            abi.encodePacked(
                '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ',
                Strings.toString(canonicalWidth),
                " ",
                Strings.toString(canonicalHeight),
                '" x="0" y="0" width="100%" height="100%" style="',
                "image-rendering:pixelated;image-rendering:-moz-crisp-edges;-ms-interpolation-mode:nearest-neighbor;",
                "background-color:transparent;background-repeat:no-repeat;background-size:100%;background-image:url(",
                imageUri,
                ');"></svg>'
            )
        );

        imageDataUri = string(
            abi.encodePacked(
                SVG_URI_PREFIX,
                Base64.encode(bytes(imageData), bytes(imageData).length)
            )
        );
    }
}