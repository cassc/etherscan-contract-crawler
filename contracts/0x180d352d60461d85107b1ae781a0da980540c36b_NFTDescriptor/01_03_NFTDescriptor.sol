// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import { Base64 } from 'base64-sol/base64.sol';
import { MultiPartRLEToSVG } from './MultiPartRLEToSVG.sol';

library NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        bytes[] parts;
        string background;
        string[] names;
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
            MultiPartRLEToSVG.SVGParams({ parts: params.parts, background: params.background }),
            palettes
        );

        string memory attributes = generateAttributes(params.names);

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', params.name, '", "description":"', params.description, '", "image": "', 'data:image/svg+xml;base64,', image, '", "attributes":', attributes, '}')
                    )
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

    function generateAttributes(string[] memory _attributes) public view returns (string memory) {
        string memory traits;
        traits = string(abi.encodePacked(
            attributeForTypeAndValue("Background", _attributes[0]),',',
            attributeForTypeAndValue("Body", _attributes[1]),',',
            attributeForTypeAndValue("Bristles", _attributes[2]),',',
            attributeForTypeAndValue("Accessory", _attributes[3]),',',
            attributeForTypeAndValue("Eyes", _attributes[4]),',',
            attributeForTypeAndValue("Mouth", _attributes[5])
            ));

        return string(abi.encodePacked(
            '[',
            traits,
            ']'
            ));
        }

    function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked(
        '{"trait_type":"',
        traitType,
        '","value":"',
        value,
        '"}'
        ));
    }
}