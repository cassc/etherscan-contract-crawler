// SPDX-License-Identifier: GPL-3.0

/// @title A library used to convert multi-part RLE compressed images to SVG

pragma solidity ^0.8.6;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library MultiPartRLEToSVG {
  using Strings for uint256;
  struct SVGParams {
    bytes parts;
    string background;
    uint16[] animatedPixels;
  }

  struct ContentBounds {
    uint8 top;
    uint8 right;
    uint8 bottom;
    uint8 left;
  }

  struct Rect {
    uint8 length;
    uint8 colorIndex;
  }

  struct DecodedImage {
    ContentBounds bounds;
    uint256 width;
    Rect[] rects;
  }

  /**
   * @notice Given RLE image parts and color palettes, merge to generate a single SVG image.
   */
  function generateSVG(SVGParams memory params, string[] storage palette) internal view returns (string memory svg) {
    // prettier-ignore
    return
      string(
        abi.encodePacked(
          '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
          '<rect width="100%" height="100%" fill="#',
          params.background,
          '" />',
          _generateSVGRects(params, palette),
          _generateUseHref(params),
          "</svg>"
        )
      );
  }

  function _generateUseHref(SVGParams memory params) private pure returns (string memory svg) {
    string memory chunk;
    for (uint256 i = 1; i <= params.animatedPixels.length; i++) {
      chunk = string(abi.encodePacked(chunk, '<use href="#animated', i.toString(), '"/>'));
    }
    return chunk;
  }

  /**
   * @notice Given RLE image parts and color palettes, generate SVG rects.
   */
  // prettier-ignore
  function _generateSVGRects(SVGParams memory params, string[] storage palette)
        private
        view
        returns (string memory svg)
    {
        string[33] memory lookup = [
            "0", "10", "20", "30", "40", "50", "60", "70", 
            "80", "90", "100", "110", "120", "130", "140", "150", 
            "160", "170", "180", "190", "200", "210", "220", "230", 
            "240", "250", "260", "270", "280", "290", "300", "310",
            "320" 
        ];
        string memory rects;
        DecodedImage memory image = _decodeRLEImage(params.parts);
        uint256 currentX = image.bounds.left;
        uint256 currentY = image.bounds.top;
        string[4] memory buffer;
        string memory part;
        uint8 blueCount;
        uint16[] memory animatedPixels = params.animatedPixels;

        for (uint256 i = 0; i < image.rects.length; i++) {
            Rect memory rect = image.rects[i];
            if (rect.colorIndex != 0) {
                buffer[0] = lookup[rect.length];      // width
                buffer[1] = lookup[currentX];         // x
                buffer[2] = lookup[currentY];         // y
                buffer[3] = palette[rect.colorIndex - 1]; // color

                bool isDroolRect = false;
                for (uint8 j = 0; j < animatedPixels.length; j++) {
                    if(i == animatedPixels[j]){
                        isDroolRect = true;
                        blueCount++;
                    }
                }  
                part = string(abi.encodePacked(part, _getChunk(buffer, isDroolRect, blueCount)));
            }

            currentX += rect.length;
            if (currentX - image.bounds.left == image.width) {
                currentX = image.bounds.left;
                currentY++;
            }
        }
        rects = string(abi.encodePacked(rects, part));
        return rects;
    }

  /**
   * @notice Return a string that consists of all rects in the provided `buffer`.
   */
  // prettier-ignore
  //TODO pure
  function _getChunk(string[4] memory buffer, bool isDroolRect, uint256 i) private pure returns (string memory) {
        if(isDroolRect){
            return string(
                abi.encodePacked(
                    '<rect id="animated', i.toString(), '" width="', buffer[0], '" height="10" x="', buffer[1], '" y="', buffer[2], '" fill="#', buffer[3], '"><animate calcMode="discrete" attributeName="height" values="10; 10; 10; 20; 30; 20; 10;"  dur="1.5s" repeatCount="indefinite" /></rect>'
                )
            );
        }else{
            return string(
                abi.encodePacked(
                    '<rect width="', buffer[0], '" height="10" x="', buffer[1], '" y="', buffer[2], '" fill="#', buffer[3], '" />'
                )
            );
        }         
    }

  /**
   * @notice Decode a single RLE compressed image into a `DecodedImage`.
   */
  function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
    ContentBounds memory bounds = ContentBounds({
      top: uint8(image[1]),
      right: uint8(image[2]),
      bottom: uint8(image[3]),
      left: uint8(image[4])
    });
    uint256 width = bounds.right - bounds.left;

    uint256 cursor;
    Rect[] memory rects = new Rect[]((image.length - 5) / 2);

    for (uint256 i = 5; i < image.length; i += 2) {
      rects[cursor] = Rect({length: uint8(image[i]), colorIndex: uint8(image[i + 1])});

      cursor++;
    }
    return DecodedImage({bounds: bounds, width: width, rects: rects});
  }
}