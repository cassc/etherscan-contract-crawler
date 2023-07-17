// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOnChainPixelArtv2 {
  /**
   * @dev Takes an encoded canvas, encoded palette, dimensions, and a background color and returns an svg.
   * Background color must end in 1 - so green would be 0x00FF001.
   * This is so 0 (which would otherwise be black) can be passed for no color.
   * Dimensions must match what the canvas was encoded with.
   */
  function render(
    uint256[] memory canvas,
    uint256[] memory palette,
    uint256 xDim,
    uint256 yDim,
    string memory svgExtension,
    uint256 paddingX,
    uint256 paddingY
  ) external pure returns (string memory svg);

  /**
   * @dev Compresses and encodes an array of pixels into an canvas of uint256s that can be rendered.
   * For example, a 3x3 image with a plus sign would be: [0, 1, 0, 1, 1, 1, 0, 1, 0]
   * Numbers are indexes into a palette, so say each pixel was a different color: [0, 1, 0, 2, 3, 4, 0, 5, 0]
   * Supplied palette would then match the indexes.
   * For example, each of these hex grey colors would correspond to the respective number 0x555555444444333333222222111111
   * So 5 would be 0x555555, 4 0x444444, etc.
   *
   * pixelCompression indicates the max number of pixels in a block. So pixelCompression 4 means you can have 2^4 (16) pixels in a block.
   * Use higher pixelCompressions for lots of repeated horizontal pixels, and lower if there aren't many sequential pixels.
   */
  function encodeColorArray(
    uint256[] memory colors,
    uint256 pixelCompression,
    uint256 colorCount
  ) external pure returns (uint256[] memory encoded);

  /**
   * @dev Composes 2 palettes together into one palette.
   * Since 0x000000 is black, we need to supply how many colors are in each palette.
   * The number of colors for a canvas are encoded within the canvas data, which is why they need to be passed explicitly.
   */

  function composePalettes(
    uint256[] memory palette1,
    uint256[] memory palette2,
    uint256 colorCount1,
    uint256 colorCount2
  ) external view returns (uint256[] memory composedPalette);

  /**
   * @dev Composes 2 encoded canvases together into one canvas.
   */

  function composeLayers(
    uint256[] memory layer1,
    uint256[] memory layer2,
    uint256 totalPixels
  ) external pure returns (uint256[] memory comp);

  /**
   * @dev Get number of colors.
   */
  function getColorCount(uint256[] memory layer) external view returns (uint256 colorCount);

  function toString(uint256 value) external pure returns (string memory);

  function toHexString(uint256 value) external pure returns (string memory);

  function base64Encode(bytes memory data) external pure returns (string memory);

  function uri(string memory data) external pure returns (string memory);

  function uriSvg(string memory data) external pure returns (string memory);
}