// SPDX-License-Identifier: MIT

import "./GeneticChain721.sol";

pragma solidity ^0.8.0;

/**
 * @title GeneticChainMetadata
 * Holds all required metadata for genetic chain projects.
 */
abstract contract GeneticChainMetadata is GeneticChain721 {

    struct IpfsAsset {
        string name;
        string hash;
    }

    uint256 public projectId;
    string public artist;
    string public description;
    string public code;
    IpfsAsset[] public libraries;
    IpfsAsset[] public assets;
    string private _tokenIpfsHash;
    string private _baseUri;

    constructor(
        string memory name,
        string memory symbol,
        uint256 projectId_,
        string memory artist_,
        string memory description_,
        string memory tokenIpfsHash_,
        string memory baseUri_,
        uint256[3] memory tokenMax,
        uint256 seed,
        address signer,
        address proxyRegistryAddress)
        GeneticChain721(
          name,
          symbol,
          tokenMax,
          seed,
          signer,
          proxyRegistryAddress)
    {
        projectId      = projectId_;
        artist         = artist_;
        description    = description_;
        _tokenIpfsHash = tokenIpfsHash_;
        _baseUri       = baseUri_;
    }

    function setProjectId(uint256 projectId_)
        public
        onlyOwner
    {
        projectId = projectId_;
    }

    function setArtist(string memory artist_)
        public
        onlyOwner
    {
        artist = artist_;
    }

    function setDescription(string memory description_)
        public
        onlyOwner
    {
        description = description_;
    }

    function setCode(string memory code_)
        public
        onlyOwner
    {
        code = code_;
    }

    function setTokenIpfsHash(string memory hash)
        public
        onlyOwner
    {
        _tokenIpfsHash = hash;
    }

    function addLibrary(string memory name, string memory hash)
        public
        onlyOwner
    {
        IpfsAsset memory lib = IpfsAsset(name, hash);
        libraries.push(lib);
    }

    function removeLibrary(uint256 index)
        public
        onlyOwner
    {
        require(index < libraries.length);
        libraries[index] = libraries[libraries.length-1];
        libraries.pop();
    }

    function getLibraryCount()
        public
        view
        returns (uint256)
    {
        return libraries.length;
    }

    function getLibraries()
        public
        view
        returns (IpfsAsset[] memory)
    {
        IpfsAsset[] memory libs = new IpfsAsset[](libraries.length);
        for (uint256 i = 0; i < libraries.length; ++i) {
          IpfsAsset storage lib = libraries[i];
          libs[i] = lib;
        }
        return libs;
    }

    function addAsset(string memory name, string memory hash)
        public
        onlyOwner
    {
        IpfsAsset memory lib = IpfsAsset(name, hash);
        assets.push(lib);
    }

    function removeAsset(uint256 index)
        public
        onlyOwner
    {
        require(index < assets.length);
        assets[index] = assets[assets.length-1];
        assets.pop();
    }

    function getAssetCount()
        public
        view
        returns (uint256)
    {
        return assets.length;
    }

    function getAssets()
        public
        view
        returns (IpfsAsset[] memory)
    {
        IpfsAsset[] memory asts = new IpfsAsset[](assets.length);
        for (uint256 i = 0; i < assets.length; ++i) {
          IpfsAsset storage ast = assets[i];
          asts[i] = ast;
        }
        return asts;
    }

    function tokenIpfsHash(uint256 /*tokenId*/)
        public
        view
        virtual
        returns (string memory)
    {
        return _tokenIpfsHash;
    }

    function baseTokenURI()
        override
        public
        view
        returns (string memory)
    {
        return string(abi.encodePacked(_baseUri, "/api/project/", Strings.toString(projectId), "/token"));
    }

    function contractURI()
        public
        view
        returns (string memory)
    {
        return string(abi.encodePacked(_baseUri, "/api/project/", Strings.toString(projectId), "/contract"));
    }

}