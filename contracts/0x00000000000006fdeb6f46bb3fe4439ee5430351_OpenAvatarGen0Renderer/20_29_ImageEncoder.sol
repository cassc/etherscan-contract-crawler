// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.20;

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Base64} from '../dependencies/Base64.sol';
import {PNG} from './PNG.sol';

/**
 * @title ImageEncoder
 * @dev A library for encoding images as PNG or SVG.
 */
contract ImageEncoder is PNG {
  /**
   * @notice Encodes the image as a Base64-encoded PNG.
   * @param data The raw image data.
   * @param width Width of the image data, in pixels.
   * @param height Height of the image data, in pixels.
   * @param alpha Whether the image has an alpha channel.
   * @return The encoded Base64-encoded PNG.
   */
  function encodeBase64PNG(bytes memory data, uint width, uint height, bool alpha) public pure returns (bytes memory) {
    bytes memory png = encodePNG(data, width, height, alpha);
    return Base64.encode(png);
  }

  /**
   * @notice Encodes the image as an SVG.
   * @param data The raw image data.
   * @param width Width of the image data, in pixels.
   * @param height Height of the image, in pixels.
   * @param alpha Whether the image has an alpha channel.
   * @param svgWidth Width of the scaled SVG, in pixels.
   * @param svgHeight Height of the scaled SVG, in pixels.
   * @return The encoded SVG.
   */
  function encodeSVG(
    bytes memory data,
    uint width,
    uint height,
    bool alpha,
    uint svgWidth,
    uint svgHeight
  ) public pure returns (bytes memory) {
    bytes memory base64PNG = encodeBase64PNG(data, width, height, alpha);
    string memory svgWidthStr = Strings.toString(svgWidth);
    string memory svgHeightStr = Strings.toString(svgHeight);
    return
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ',
        svgWidthStr,
        ' ',
        svgHeightStr,
        '">\n\t<foreignObject width="',
        svgWidthStr,
        '" height="',
        svgHeightStr,
        '">\n\t\t<img xmlns="http://www.w3.org/1999/xhtml" width="',
        svgWidthStr,
        '" height="',
        svgHeightStr,
        '" style="image-rendering: pixelated;" src="data:image/png;base64,',
        base64PNG,
        '"/>\n\t</foreignObject>\n</svg>'
      );
  }

  /**
   * @notice Encodes the image as a Base64-encoded SVG.
   * @param data The raw image data.
   * @param width Width of the image data, in pixels.
   * @param height Height of the image, in pixels.
   * @param alpha Whether the image has an alpha channel.
   * @param svgWidth Width of the scaled SVG, in pixels.
   * @param svgHeight Height of the scaled SVG, in pixels.
   * @return The encoded Base64-encoded SVG.
   */
  function encodeBase64SVG(
    bytes memory data,
    uint width,
    uint height,
    bool alpha,
    uint svgWidth,
    uint svgHeight
  ) public pure returns (bytes memory) {
    bytes memory svg = encodeSVG(data, width, height, alpha, svgWidth, svgHeight);
    return Base64.encode(svg);
  }
}