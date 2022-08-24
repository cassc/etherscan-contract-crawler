// SPDX-License-Identifier: GPL-3.0

/// @title The Nouns NFT descriptor

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { Base64 } from 'base64-sol/base64.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import { INounsDescriptor } from './interfaces/INounsDescriptor.sol';
import { ISuNounsRenderer } from './interfaces/ISuNounsRenderer.sol';
import { INounsSeeder } from './interfaces/INounsSeeder.sol';

contract SuNounsRenderer is ISuNounsRenderer, Ownable {
    using Strings for uint256;

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public override isDataURIEnabled = true;

    // Base URI
    string public override baseURI;

    // The Nouns token URI descriptor
    INounsDescriptor public nounsDescriptor;

    constructor(
        INounsDescriptor _descriptor
    ) {
        nounsDescriptor = _descriptor;
    }

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleDataURIEnabled() external override onlyOwner {
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setNounsDescriptor(INounsDescriptor _descriptor) external override onlyOwner {
        nounsDescriptor = _descriptor;

        emit NounsDescriptorUpdated(_descriptor);
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for an official Nouns DAO noun.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view override returns (string memory) {
        if (isDataURIEnabled) {
            return dataURI(tokenId, seed);
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
    
    function _constructSVGImage(bytes memory baseImage) private pure returns (string memory) {

        // Locate the SVG's first closing SVG tag'/>'
        bool found = false;
        uint loc = 1;
        for (; loc < baseImage.length; loc++) {
            if ( baseImage[loc-1] == '/' && baseImage[loc] == '>' ) {
                found = true;
                break;
            }
        }
        loc++; // loc is the first byte of the rest of the image
        require(found, 'Invalid Noun SVG' );
        require(loc < baseImage.length, 'Invalid Noun SVG length' );
        
        // Copy the remainder of the SVG
        bytes memory _artSVG = new bytes(baseImage.length-loc);

        for(uint i=0; i<baseImage.length-loc; i++){
            _artSVG[i] = baseImage[i+loc];
        }

        return Base64.encode(
                    bytes(
                        abi.encodePacked('<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" transform="rotate(180 0 0 )">',
                                         '<defs><radialGradient id="radial_sunouns" cx="50%" cy="50%" r="75%" fx="50%" fy="30%" >',
                                         '<stop offset="0%" stop-color="#e1d7d5" />',
                                         '<stop offset="100%" stop-color="black" />',
                                         '</radialGradient></defs>',
                                         '<rect width="100%" height="100%" fill="url(#radial_sunouns)" />',
                                         _artSVG
                        
                        )
                    )
                );
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(INounsSeeder.Seed memory seed) external view override returns (string memory) {
        return _constructSVGImage(Base64.decode(nounsDescriptor.generateSVGImage(seed)));
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for an official Nouns DAO noun.
     */
    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) public view override returns (string memory) {
        string memory nounId = tokenId.toString();
        string memory name = string(abi.encodePacked('sunoun ', nounId));
        string memory description = string(abi.encodePacked('sunoun ', nounId, ' is a member of the Underground'));

        // Call the upstream Noun  Descriptor to get the dataURI
        // Then 
        return genericDataURI(name, description, seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        INounsSeeder.Seed memory seed
    ) public view override returns (string memory) {
        
        string memory image = _constructSVGImage(Base64.decode(nounsDescriptor.generateSVGImage(seed)));

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    }

}