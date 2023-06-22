// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//------------------------------------------------------------------------------
//    _______                   __   __        ______ __          __
//   |     __|-----.-----.-----|  |_|__|----. |      |  |--.---.-|__|-----.
//   |    |  |  -__|     |  -__|   _|  |  __| |   ---|     |  _  |  |     |
//   |_______|_____|__|__|_____|____|__|____| |______|__|__|___._|__|__|__|
//
//------------------------------------------------------------------------------
// Genetic Chain: GeneticChainMetadata
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

import "./GeneticChain721.sol";

//------------------------------------------------------------------------------
// GeneticChainMetadata
//------------------------------------------------------------------------------

/**
 * @title GeneticChainMetadata
 * Holds all required metadata for Genetic Chain projects.
 */
abstract contract GeneticChainMetadata is GeneticChain721
{

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    uint256 constant public projectId  = 7;
    string constant public artist      = "Matt Griffin";
    string constant public description = "The Midnight Runner Pass provides holders with membership to the Genetic Chain Platform.  Passes will unlock access to pre-sales, free mints, future GC programs, as well as access to live events at the GC gallery.";

    string private _tokenIpfsHash;
    string private _baseUri;

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        address[3] memory cards,
        string memory tokenIpfsHash_,
        string memory baseUri_,
        uint256 seed,
        address proxyRegistryAddress)
        GeneticChain721(
          cards,
          seed,
          proxyRegistryAddress)
    {
        _tokenIpfsHash = tokenIpfsHash_;
        _baseUri       = baseUri_;
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    function tokenIpfsHash(uint256 /*tokenId*/)
        public
        view
        virtual
        returns (string memory)
    {
        return _tokenIpfsHash;
    }

    //-------------------------------------------------------------------------

    function baseTokenURI()
        override public view returns (string memory)
    {
        return string(abi.encodePacked(_baseUri, "/api/project/", Strings.toString(projectId), "/token"));
    }

    //-------------------------------------------------------------------------

    function contractURI()
        public view returns (string memory)
    {
        return string(abi.encodePacked(_baseUri, "/api/project/", Strings.toString(projectId), "/contract"));
    }

}