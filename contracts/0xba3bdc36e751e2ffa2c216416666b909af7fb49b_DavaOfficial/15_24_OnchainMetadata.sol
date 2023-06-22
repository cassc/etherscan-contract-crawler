//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import {IPartCollection} from "../interfaces/IPartCollection.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library OnchainMetadata {
    using Strings for uint256;

    string private constant SVG_START_LINE =
        "<svg xmlns='http://www.w3.org/2000/svg' width='1000' height='1000' viewBox='0 0 1000 1000'>";
    string private constant SVG_END_LINE = "</svg>";
    string private constant SVG_IMG_START_LINE = "<image href='";
    string private constant SVG_IMG_END_LINE = "' width='100%'/>";

    function toMetadata(
        string memory name,
        string memory description,
        string[] memory imgURIs,
        string memory externalImgUri,
        string memory externalUri,
        IPartCollection.Attribute[] memory attributes
    ) internal pure returns (string memory) {
        bytes memory metadata = abi.encodePacked(
            'data:application/json;utf8,{"name":"',
            name,
            '","external_url":"',
            externalUri,
            '","description":"',
            description,
            '","attributes":['
        );

        for (uint256 i = 0; i < attributes.length; i += 1) {
            IPartCollection.Attribute memory attribute = attributes[i];
            metadata = abi.encodePacked(
                metadata,
                '{"trait_type":"',
                attribute.trait_type,
                '","value":"',
                attribute.value,
                '"}'
            );
            if (i < attributes.length - 1) {
                metadata = abi.encodePacked(metadata, ",");
            }
        }

        metadata = abi.encodePacked(
            metadata,
            '],"raw_image":"data:image/svg+xml;utf8,',
            compileImages(imgURIs),
            '","image":"',
            externalImgUri,
            '"}'
        );

        return string(metadata);
    }

    function compileImages(string[] memory imgURIs)
        internal
        pure
        returns (string memory)
    {
        string memory accumulator;

        for (uint256 i = 0; i < imgURIs.length; i += 1) {
            accumulator = string(
                abi.encodePacked(accumulator, toSVGImage(imgURIs[i]))
            );
        }

        return
            string(abi.encodePacked(SVG_START_LINE, accumulator, SVG_END_LINE));
    }

    function toSVGImage(string memory imgUri)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(SVG_IMG_START_LINE, imgUri, SVG_IMG_END_LINE)
            );
    }
}