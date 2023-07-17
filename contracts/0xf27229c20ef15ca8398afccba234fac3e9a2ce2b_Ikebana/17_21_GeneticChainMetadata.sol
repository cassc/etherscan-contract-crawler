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

    uint256 constant public projectId  = 5;
    string constant public artist      = "Jento";
    string constant public description = "A digital abstraction of the Ikebana art's quest for harmony, balance and grace. Dancing forever in honor of beauty.";

    string public code;
    IpfsAsset[] public libraries;
    string private _baseUri;

    constructor(
        IpfsAsset memory lib,
        string memory code_,
        string memory baseUri_,
        uint256[3] memory tokenMax,
        uint256 seed,
        address proxyRegistryAddress)
        GeneticChain721(
          tokenMax,
          seed,
          proxyRegistryAddress)
    {
        code     = code_;
        _baseUri = baseUri_;
        addLibrary(lib.name, lib.hash);
    }

    function setCode(string memory code_)
        public
        onlyOwner
        notLocked
    {
        code = code_;
    }

    function addLibrary(string memory name, string memory hash)
        public
        onlyOwner
        notLocked
    {
        IpfsAsset memory lib = IpfsAsset(name, hash);
        libraries.push(lib);
    }

    function removeLibrary(uint256 index)
        public
        onlyOwner
        notLocked
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