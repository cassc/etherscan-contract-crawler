// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//-----------------------------------------------------------------------------
// Jerkface Genesis Collection
//-----------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//-----------------------------------------------------------------------------

import "./GeneticChain721.sol";

//------------------------------------------------------------------------------
// Jerkface
//------------------------------------------------------------------------------

/**
 * @title Jerkface Genesis Collection
 */
contract JerkfaceGenesis is GeneticChain721
{

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // token info
    string private _baseUri;
    string private _tokenIpfsHash;

    // contract info
    string public _contractUri;

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        string memory baseUri_,
        string memory ipfsHash_,
        string memory contractUri_,
        uint16[4] memory pmax,
        uint16[4] memory max)
        GeneticChain721(pmax, max)
    {
        _baseUri       = baseUri_;
        _tokenIpfsHash = ipfsHash_;
        _contractUri   = contractUri_;
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    function setTokenIpfsHash(string memory hash)
        public
        onlyOwner
    {
        if (bytes(hash).length == 0) {
            delete _tokenIpfsHash;
        } else {
            _tokenIpfsHash = hash;
        }
    }

    //-------------------------------------------------------------------------

    function setBaseTokenURI(string memory baseUri)
        public
        onlyOwner
    {
        _baseUri = baseUri;
    }

    //-------------------------------------------------------------------------
    // ERC721Metadata
    //-------------------------------------------------------------------------

    function baseTokenURI()
        public
        view
        returns (string memory)
    {
        return _baseUri;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Returns uri of a token.  Not guarenteed token exists.
     */
    function tokenURI(uint256 tokenId)
        override
        public
        view
        returns (string memory)
    {
        return bytes(_tokenIpfsHash).length == 0
            ? string(abi.encodePacked(
                baseTokenURI(), "/", Strings.toString(tokenId)))
            : string(abi.encodePacked(
                baseTokenURI(),
                    "/", _tokenIpfsHash,
                    "/", Strings.toString(tokenId)));
    }

    //-------------------------------------------------------------------------
    // contractUri
    //-------------------------------------------------------------------------

    function setContractURI(string memory contractUri)
        external onlyOwner
    {
        _contractUri = contractUri;
    }

    //-------------------------------------------------------------------------

    function contractURI()
        public view
        returns (string memory)
    {
        return _contractUri;
    }

}