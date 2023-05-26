// SPDX-License-Identifier: MIT

import "./GeneticChain721.sol";

pragma solidity ^0.8.0;

/**
 * @title GeneticChainMetadata
 * Holds all required metadata for genetic chain projects.
 */
abstract contract GeneticChainMetadata is GeneticChain721 {

    uint256 public projectId;
    string public artist;
    string public description;
    string public code;
    string private _baseUri;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 projectId_,
        string memory artist_,
        string memory description_,
        string memory code_,
        string memory baseUri_,
        uint256 publicMax_,
        uint256 privateMax_,
        uint256 seed_,
        address proxyRegistryAddress)
        GeneticChain721(
          name_,
          symbol_,
          publicMax_,
          privateMax_,
          seed_,
          proxyRegistryAddress)
    {
        projectId   = projectId_;
        artist      = artist_;
        description = description_;
        code        = code_;
        _baseUri    = baseUri_;
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