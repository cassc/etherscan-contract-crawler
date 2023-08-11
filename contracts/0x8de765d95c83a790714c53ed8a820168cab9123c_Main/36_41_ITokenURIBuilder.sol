// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.19;

import "./ISVGWrapper.sol";

struct TokenURIOptions {
    bytes imageUri;
    bytes attributes;
    uint256 tokenId;
    string description;
    string externalUrl;
    string prefix;    
}

enum SVGWrapperTarget {
    ImageDataWithNativeImage,
    ImageData,
    Image,
    None
}

interface ITokenURIBuilder {
    function encode(TokenURIOptions calldata options) external view returns (bytes memory);
    function encodeSVGWrapped(TokenURIOptions calldata options, ISVGWrapper svg, SVGWrapperTarget target, uint256 width, uint256 height) external view returns (bytes memory);
}