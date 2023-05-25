// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Base64.sol";
import "../libraries/BaseContract.sol";

contract ArtworkFacet is
	BaseContract
{
	function setAttributeType(
		uint8 attributeTypeId,
		string memory name,
		string memory description,
		uint8 zIndex
	)
		public onlyOwner
	{
		getState().attributeTypes[attributeTypeId].name = name;
		getState().attributeTypes[attributeTypeId].description = description;
		getState().attributeTypes[attributeTypeId].zIndex = zIndex;
	}

	function setAttributeSelection(
		uint8 attributeTypeId,
		uint8 attributeSelectionId,
		string memory name,
		string memory description,
		string memory dataUri
	)
		public onlyOwner
	{
		getState().attributeTypes[attributeTypeId].selections[attributeSelectionId].name = name;
		getState().attributeTypes[attributeTypeId].selections[attributeSelectionId].description = description;
		getState().attributeTypes[attributeTypeId].selections[attributeSelectionId].dataUri = dataUri;
	}

	// =================================
	// SVG
	// =================================

    function generateSvg(uint256 tokenId) 
        external 
        view 
		returns (string memory) 
    {
        return
            Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" image-rendering="pixelated" height="24" width="24">',
								'<image xlink:href="', getState().attributeTypes[0].selections[getState().attributesActive[tokenId][0]].dataUri, '"/>',
								'<image xlink:href="', getState().attributeTypes[1].selections[getState().attributesActive[tokenId][1]].dataUri, '"/>',
								'<image xlink:href="', getState().attributeTypes[2].selections[getState().attributesActive[tokenId][2]].dataUri, '"/>', 
							'</svg>'
                        )
                    )
			)
		);
    }
}