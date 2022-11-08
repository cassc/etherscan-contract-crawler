// SPDX-License-Identifier: MIT

/// @title A library used to construct ERC721 token URIs and SVG images

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

pragma solidity ^0.8.17;

import { Base64 } from 'base64-sol/base64.sol';
import { MultiPartRLEToSVG } from './MultiPartRLEToSVG.sol';

library NFTDescriptor {
  struct TokenURIParams {
    string name;
    string description;
    string background;
    bytes[] elements;
    string attributes;
    uint256 advantage;
    uint8 width;
    uint8 height;
  }

  /**
   * @notice Construct an ERC721 token URI.
   */
  function constructTokenURI(TokenURIParams memory params, mapping(uint8 => string[]) storage palettes)
    public
    view
    returns (string memory)
  {
    string memory image = generateSVGImage(
      MultiPartRLEToSVG.SVGParams({
        background: params.background,
        elements: params.elements,
        advantage: params.advantage,
        width: uint256(params.width),
        height: uint256(params.height)
      }),
      palettes
    );

    string memory attributesJson;

    if (bytes(params.attributes).length > 0) {
      attributesJson = string.concat(' "attributes":', params.attributes, ',');
    } else {
      attributesJson = string.concat('');
    }

    // prettier-ignore
    return string.concat(
			'data:application/json;base64,',
			Base64.encode(
				bytes(
					string.concat('{"name":"', params.name, '",',
					' "description":"', params.description, '",',
					attributesJson,
					' "image": "', 'data:image/svg+xml;base64,', image, '"}')
				)
			)
    );
  }

  /**
   * @notice Generate an SVG image for use in the ERC721 token URI.
   */
  function generateSVGImage(MultiPartRLEToSVG.SVGParams memory params, mapping(uint8 => string[]) storage palettes)
    public
    view
    returns (string memory svg)
  {
    return Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(params, palettes)));
  }
}