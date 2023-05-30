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
    // structs
    //-------------------------------------------------------------------------

    struct IpfsAsset {
        string name;
        string hash;
    }

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    uint256 constant public projectId  = 6;
    string constant public artist      = "Klabelkholosh";
    string constant public description = "Living threads of colour pulled across an unseen canvas, creating mood and space.";

    string public code;
    string private _baseUri;
    IpfsAsset[] public libraries;

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

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

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    function setCode(string memory code_)
        public onlyOwner notLocked
    {
        code = code_;
    }

    //-------------------------------------------------------------------------

    function addLibrary(string memory name, string memory hash)
        public onlyOwner notLocked
    {
        IpfsAsset memory lib = IpfsAsset(name, hash);
        libraries.push(lib);
    }

    //-------------------------------------------------------------------------

    function removeLibrary(uint256 index)
        public onlyOwner notLocked
    {
        require(index < libraries.length);
        libraries[index] = libraries[libraries.length-1];
        libraries.pop();
    }

    //-------------------------------------------------------------------------

    function getLibraryCount()
        public view returns (uint256)
    {
        return libraries.length;
    }

    //-------------------------------------------------------------------------

    function getLibraries()
        public view returns (IpfsAsset[] memory)
    {
        IpfsAsset[] memory libs = new IpfsAsset[](libraries.length);
        for (uint256 i = 0; i < libraries.length; ++i) {
          IpfsAsset storage lib = libraries[i];
          libs[i] = lib;
        }
        return libs;
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