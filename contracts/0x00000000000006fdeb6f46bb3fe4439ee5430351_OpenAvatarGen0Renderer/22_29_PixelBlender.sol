// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PixelBlender
 * @dev This contract blends pixels together.
 */
contract PixelBlender {
  /**
   * @notice Blend two pixels together.
   * @param foreground The foreground pixel color value.
   * @param background The background pixel color value.
   * @param foregroundAlpha The alpha of the foreground pixel.
   * @return The blended pixel color value.
   */
  function blendPixel(uint8 foreground, uint8 background, uint8 foregroundAlpha) internal pure returns (uint8) {
    return uint8((uint(foreground) * uint(foregroundAlpha) + uint(background) * (255 - uint(foregroundAlpha))) / 255);
  }

  /**
   * @notice Blend two alpha values together.
   * @param foregroundAlpha The foreground alpha value.
   * @param backgroundAlpha The background alpha value.
   * @return The blended alpha value.
   */
  function blendAlpha(uint8 foregroundAlpha, uint8 backgroundAlpha) internal pure returns (uint8) {
    if (foregroundAlpha == 255) return 255;
    if (backgroundAlpha == 255) return 255;
    return uint8(uint(foregroundAlpha) + (uint(backgroundAlpha) * (255 - uint(foregroundAlpha))) / 255);
  }
}