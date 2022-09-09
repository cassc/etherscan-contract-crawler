// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

import "../graphics/IPixelRenderer.sol";
import "../graphics/IAnimationEncoder.sol";
import "../graphics/ISVGWrapper.sol";

interface IBuilder {
    function getCanonicalSize() external view returns (uint width, uint height);
    function getImage(IPixelRenderer renderer, IAnimationEncoder encoder, uint8[] memory metadata, uint tokenId) external view returns (string memory);
}