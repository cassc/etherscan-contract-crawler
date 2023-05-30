// SPDX-License-Identifier: MIT

/**
 * ░█▄█░▄▀▄▒█▀▒▄▀▄░░░▒░░░▒██▀░█▀▄░█░▀█▀░█░▄▀▄░█▄░█░▄▀▀░░░█▄░█▒█▀░▀█▀
 * ▒█▒█░▀▄▀░█▀░█▀█▒░░▀▀▒░░█▄▄▒█▄▀░█░▒█▒░█░▀▄▀░█▒▀█▒▄██▒░░█▒▀█░█▀░▒█▒
 * 
 * Made with 🧡 by Kreation.tech
 */
pragma solidity ^0.8.6;


import {MetadataHelper} from "./MetadataHelper.sol";

/**
 * Shared NFT logic for rendering metadata associated with editions
 */
contract EditionsMetadataHelper is MetadataHelper {

    /**
     * Generates edition metadata from storage information as base64-json blob
     * Combines the media data and metadata
     * 
     * @param name Name of NFT in metadata
     * @param description Description of NFT in metadata
     * @param contentUrl URL of content to render
     * @param thumbnailUrl optional URL of a thumbnail to render, for animated content only
     * @param tokenOfEdition unique identifier of a token edition
     * @param size total count of editions
     */
    function createTokenURI(string memory name, string memory description, string memory contentUrl, string memory thumbnailUrl, uint256 tokenOfEdition, uint256 size) external pure returns (string memory) {
        string memory _tokenMediaData = tokenMediaData(contentUrl, thumbnailUrl, tokenOfEdition);
        bytes memory json = createMetadata(name, description, _tokenMediaData, tokenOfEdition, size);
        return encodeMetadata(json);
    }

    /** 
     * Function to create the metadata json string for the nft edition
     * 
     * @param name Name of NFT in metadata
     * @param description Description of NFT in metadata
     * @param mediaData Data for media to include in json object
     * @param tokenOfEdition Token ID for specific token
     * @param size Size of entire edition to show
    */
    function createMetadata(string memory name, string memory description, string memory mediaData, uint256 tokenOfEdition, uint256 size) public pure returns (bytes memory) {
        bytes memory sizeText;
        if (size > 0) {
            sizeText = abi.encodePacked("/", numberToString(size));
        }
        return abi.encodePacked('{"name":"', name, " ", numberToString(tokenOfEdition), sizeText, '","description":"', description, '","',
                mediaData, 'properties":{"number":', numberToString(tokenOfEdition), ',"name":"', name, '"}}');
    }

    /** 
     * Generates edition metadata from storage information as base64-json blob
     * Combines the media data and metadata
     * 
     * @param contentUrl URL of image to render for edition
     * @param thumbnailUrl index of the content type to render for edition
     * @param tokenOfEdition token identifier
     */
    function tokenMediaData(string memory contentUrl, string memory thumbnailUrl, uint256 tokenOfEdition) public pure returns (string memory) {
        if (bytes(thumbnailUrl).length == 0) {
            return string(
                abi.encodePacked(
                    'image":"', contentUrl, "?id=", numberToString(tokenOfEdition),'","'));
        } else {
            return string(
                abi.encodePacked(
                    'image":"', thumbnailUrl, "?id=", numberToString(tokenOfEdition),'","animation_url":"', contentUrl, "?id=", numberToString(tokenOfEdition),'","'));
        }
    }
}