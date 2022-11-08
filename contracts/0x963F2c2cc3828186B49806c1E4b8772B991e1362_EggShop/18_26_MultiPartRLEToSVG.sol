// SPDX-License-Identifier: MIT

/// @title A library used to convert multi-part RLE compressed images to SVG

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

/*
Adopted from Nouns.wtf source code
Modification allow for 48x48 pixel & 32x32 RLE images & using string.concat
*/

pragma solidity ^0.8.17;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

library MultiPartRLEToSVG {
  using Strings for uint256;
  struct SVGParams {
    string background;
    bytes[] elements;
    uint256 advantage;
    uint256 width;
    uint256 height;
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
    uint8 paletteIndex;
    ContentBounds bounds;
    Rect[] rects;
  }

  /**
   * @notice Given RLE image elements and color palettes, merge to generate a single SVG image.
   */
  function generateSVG(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
    internal
    view
    returns (string memory svg)
  {
    string memory width = (params.width * 10).toString();
    string memory height = (params.width * 10).toString();
    string memory _background = '';
    if (keccak256(abi.encodePacked(params.background)) != keccak256(abi.encodePacked('------'))) {
      _background = string.concat('<rect width="100%" height="100%" fill="#', params.background, '" />');
    }
    return
      string.concat(
        '<svg width="',
        width,
        '" height="',
        height,
        '"',
        ' viewBox="0 0 ',
        width,
        ' ',
        height,
        '"',
        ' xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
        _background,
        _generateSVGRects(params, palettes),
        '</svg>'
      );
  }

  /**
   * @notice Given RLE image elements and color palettes, generate SVG rects.
   */
  // prettier-ignore
  function _generateSVGRects(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
			private
			view
			returns (string memory svg)
    {
			string[49] memory lookup;

			// This is a lookup table that enables very cheap int to string
			// conversions when operating on a set of predefined integers.
			// This is used below to convert the integer length of each rectangle
			// in a 32x32 pixel grid to the string representation of the length
			// in a 320x320 pixel grid.
			// For example: A length of 3 gets mapped to '30'.
			// This lookup can be used for up to a 48x48 pixel grid
				lookup = [
					'0', '10', '20', '30', '40', '50', '60', '70',
					'80', '90', '100', '110', '120', '130', '140', '150',
					'160', '170', '180', '190', '200', '210', '220', '230',
					'240', '250', '260', '270', '280', '290', '300', '310',
					'320', '330', '340', '350', '360', '370', '380', '390',
					'400', '410', '420', '430', '440', '450', '460', '470',
					'480'
        ];

			// The string of SVG rectangles
			string memory rects;
			// Loop through all element create svg rects
			uint256 elementSize = 0;
			for (uint8 p = 0; p < params.elements.length; p++) {
				elementSize = elementSize + params.elements[p].length;

				// Convert the element data into a format that's easier to consume
    		// than a byte array.
				DecodedImage memory image = _decodeRLEImage(params.elements[p]);

				// Get the color palette used by the current element (`params.elements[p]`)
				string[] storage palette = palettes[image.paletteIndex];

				// These are the x and y coordinates of the rect that's currently being drawn.
    		// We start at the top-left of the pixel grid when drawing a new element.

				uint256 currentX = image.bounds.left;
				uint256 currentY = image.bounds.top;

				// The `cursor` and `buffer` are used here as a gas-saving technique.
				// We load enough data into a string array to draw four rectangles.
				// Once the string array is full, we call `_getChunk`, which writes the
				// four rectangles to a `chunk` variable before concatenating them with the
				// existing element string. If there is remaining, unwritten data inside the
				// `buffer` after we exit the rect loop, it will be written before the
				// element rectangles are merged with the existing element data.
				// This saves gas by reducing the size of the strings we're concatenating
				// during most loops.
				uint256 cursor;
				string[16] memory buffer;

				// The element rectangles
				string memory element;
				for (uint256 i = 0; i < image.rects.length; i++) {
					Rect memory rect = image.rects[i];
					// Skip fully transparent rectangles. Transparent rectangles
					// always have a color index of 0.
					if (rect.colorIndex != 0) {
							// Load the rectangle data into the buffer
							buffer[cursor] = lookup[rect.length];          // width
							buffer[cursor + 1] = lookup[currentX];         // x
							buffer[cursor + 2] = lookup[currentY];         // y
							buffer[cursor + 3] = palette[rect.colorIndex]; // color

							cursor += 4;

							if (cursor >= 16) {
								// Write the rectangles from the buffer to a string
								// and concatenate with the existing element string.
								element = string.concat(element, _getChunk(cursor, buffer));
								cursor = 0;
							}
					}

					// Move the x coordinate `rect.length` pixels to the right
					currentX += rect.length;

					// If the right bound has been reached, reset the x coordinate
					// to the left bound and shift the y coordinate down one row.
					if (currentX == image.bounds.right) {
							currentX = image.bounds.left;
							currentY++;
					}
				}

				// If there are unwritten rectangles in the buffer, write them to a
   			// `chunk` and concatenate with the existing element data.
				if (cursor != 0) {
					element = string.concat(element, _getChunk(cursor, buffer));
				}

				// Concatenate the element with all previous elements
				rects = string.concat(rects, element);

			}
			return rects;
    }

  /**
   * @notice Return a string that consists of all rects in the provided `buffer`.
   */
  // prettier-ignore
  function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
		string memory chunk;
		for (uint256 i = 0; i < cursor; i += 4) {
			chunk = string.concat(
					chunk,
					'<rect width="', buffer[i], '" height="10" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
			);
		}
		return chunk;
  }

  /**
   * @notice Decode a single RLE compressed image into a `DecodedImage`.
   */
  function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
    uint8 paletteIndex = uint8(image[0]);
    ContentBounds memory bounds = ContentBounds({
      top: uint8(image[1]),
      right: uint8(image[2]),
      bottom: uint8(image[3]),
      left: uint8(image[4])
    });

    uint256 cursor;

    // why is it length - 5? and why divide by 2?
    Rect[] memory rects = new Rect[]((image.length - 5) / 2);
    for (uint256 i = 5; i < image.length; i += 2) {
      rects[cursor] = Rect({ length: uint8(image[i]), colorIndex: uint8(image[i + 1]) });
      cursor++;
    }
    return DecodedImage({ paletteIndex: paletteIndex, bounds: bounds, rects: rects });
  }
}