// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//-----------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//-----------------------------------------------------------------------------
 /*\_____________________________________________________________   .¿yy¿.   __
 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM```````/MMM\\\\\  \\$$$$$$S/  .
 MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM``   `/  yyyy    ` _____J$$$^^^^/%#//
 MMMMMMMMMMMMMMMMMMMYYYMMM````      `\/  .¿yü  /  $ùpüüü%%% | ``|//|` __
 MMMMMYYYYMMMMMMM/`     `| ___.¿yüy¿.  .d$$$$  /  $$$$SSSSM |   | ||  MMNNNNNNM
 M/``      ``\/`  .¿ù%%/.  |.d$$$$$$$b.$$$*°^  /  o$$$  __  |   | ||  MMMMMMMMM
 M   .¿yy¿.     .dX$$$$$$7.|$$$$"^"$$$$$$o`  /MM  o$$$  MM  |   | ||  MMYYYYYYM
   \\$$$$$$S/  .S$$o"^"4$$$$$$$` _ `SSSSS\        ____  MM  |___|_||  MM  ____
  J$$$^^^^/%#//oSSS`    YSSSSSS  /  pyyyüüü%%%XXXÙ$$$$  MM  pyyyyyyy, `` ,$$$o
 .$$$` ___     pyyyyyyyyyyyy//+  /  $$$$$$SSSSSSSÙM$$$. `` .S&&T$T$$$byyd$$$$\
 \$$7  ``     //o$$SSXMMSSSS  |  /  $$/&&X  _  ___ %$$$byyd$$$X\$`/S$$$$$$$S\
 o$$l   .\\YS$$X>$X  _  ___|  |  /  $$/%$$b.,.d$$$\`7$$$$$$$$7`.$   `"***"`  __
 o$$l  __  7$$$X>$$b.,.d$$$\  |  /  $$.`7$$$$$$$$%`  `*+SX+*|_\\$  /.     ..\MM
 o$$L  MM  !$$$$\$$$$$$$$$%|__|  /  $$// `*+XX*\'`  `____           ` `/MMMMMMM
 /$$X, `` ,S$$$$\ `*+XX*\'`____  /  %SXX .      .,   NERV   ___.¿yüy¿.   /MMMMM
  7$$$byyd$$$>$X\  .,,_    $$$$  `    ___ .y%%ü¿.  _______  $.d$$$$$$$S.  `MMMM
  `/S$$$$$$$\\$J`.\\$$$ :  $\`.¿yüy¿. `\\  $$$$$$S.//XXSSo  $$$$$"^"$$$$.  /MMM
 y   `"**"`"Xo$7J$$$$$\    $.d$$$$$$$b.    ^``/$$$$.`$$$$o  $$$$\ _ 'SSSo  /MMM
 M/.__   .,\Y$$$\\$$O` _/  $d$$$*°\ pyyyüüü%%%W $$$o.$$$$/  S$$$. `  S$To   MMM
 MMMM`  \$P*$$X+ b$$l  MM  $$$$` _  $$$$$$SSSSM $$$X.$T&&X  o$$$. `  S$To   MMM
 MMMX`  $<.\X\` -X$$l  MM  $$$$  /  $$/&&X      X$$$/$/X$$dyS$$>. `  S$X%/  `MM
 MMMM/   `"`  . -$$$l  MM  yyyy  /  $$/%$$b.__.d$$$$/$.'7$$$$$$$. `  %SXXX.  MM
 MMMMM//   ./M  .<$$S, `` ,S$$>  /  $$.`7$$$$$$$$$$$/S//_'*+%%XX\ `._       /MM
 MMMMMMMMMMMMM\  /$$$$byyd$$$$\  /  $$// `*+XX+*XXXX      ,.      .\MMMMMMMMMMM
 GENETIC/MMMMM\.  /$$$$$$$$$$\|  /  %SXX  ,_  .      .\MMMMMMMMMMMMMMMMMMMMMMMM
 CHAIN/MMMMMMMM/__  `*+YY+*`_\|  /_______//MMMMMMMMMMMMMMMMMMMMMMMMMMM/-/-/-\*/
//-----------------------------------------------------------------------------
// Genetic Chain: SereneAnimo
//-----------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//-----------------------------------------------------------------------------

import "./GeneticChain721.sol";

//------------------------------------------------------------------------------
// GeneticChainMetadata
//------------------------------------------------------------------------------

/**
 * @title GeneticChain | Project #11 | SereneAnimo
 */
contract SereneAnimo is GeneticChain721
{

    //-------------------------------------------------------------------------
    // structs
    //-------------------------------------------------------------------------

    struct IpfsAsset {
        string name;
        string hash;
    }

    //-------------------------------------------------------------------------

    struct ArtState {
        int64 sdfblend;
        int64 speed;
        int64 size;
        bool _set;
    }

    //-------------------------------------------------------------------------
    // events
    //-------------------------------------------------------------------------

    event StateChange(address indexed owner, uint256 tokenId, ArtState state);

    //-------------------------------------------------------------------------
    // constants
    //-------------------------------------------------------------------------

    // erc721 metadata
    string constant private __name   = "Serene Animo";
    string constant private __symbol = "GCP11";

    // metadata
    uint256 constant public projectId  = 11;
    string constant public artist      = "atara";
    string constant public description = "Calming shapes and colors inspire to relax and let the mind wonder.";

    // addresses
    address constant private _artistAddress = 0xceC15d87719feDEcA61F7d11D2d205a4C0628517;

    // token data
    uint256 private immutable _seed;

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    string public code;
    string private _baseUri;
    IpfsAsset[] public libraries;

    // token state
    mapping(uint256 => ArtState) _state;

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        IpfsAsset memory lib,
        string memory baseUri_,
        uint256[3] memory tokenMax_,
        uint256 seed,
        address proxyRegistryAddress)
        GeneticChain721(
          __name,
          __symbol,
          tokenMax_,
          proxyRegistryAddress)
    {
        _baseUri = baseUri_;
        _seed    = seed;
        addLibrary(lib.name, lib.hash);
        registerArtistAddress(_artistAddress);
    }

    //-------------------------------------------------------------------------
    // accessors
    //-------------------------------------------------------------------------

    function setCode(string memory code_)
        public
        onlyOwner
        notLocked
    {
        code = code_;
    }

    //-------------------------------------------------------------------------

    function addLibrary(string memory name, string memory hash)
        public
        onlyOwner
        notLocked
    {
        IpfsAsset memory lib = IpfsAsset(name, hash);
        libraries.push(lib);
    }

    //-------------------------------------------------------------------------

    function removeLibrary(uint256 index)
        public
        onlyOwner
        notLocked
    {
        require(index < libraries.length);
        libraries[index] = libraries[libraries.length-1];
        libraries.pop();
    }

    //-------------------------------------------------------------------------

    function getLibraryCount()
        public
        view
        returns (uint256)
    {
        return libraries.length;
    }

    //-------------------------------------------------------------------------

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
        return string(abi.encodePacked(
            baseTokenURI(), "/", Strings.toString(tokenId), "/meta"));
    }

    //-------------------------------------------------------------------------
    // generative
    //-------------------------------------------------------------------------

    /**
     * @dev Low-Gas alternative to storing the hash on the chain.
     * @return generated hash associated with valid a token.
     */
    function tokenHash(uint256 tokenId)
        public
        view
        validTokenId(tokenId)
        returns (bytes32)
    {
      return keccak256(
          abi.encodePacked(
              _seed,
              tokenId,
              tokenId - 1,
              keccak256(abi.encodePacked(tokenId, tokenId - 1)),
              address(this)));
    }

    //-------------------------------------------------------------------------
    // state
    //-------------------------------------------------------------------------

    function state(uint256 tokenId)
        public
        view
        validTokenId(tokenId)
        returns (int64 sdfblend, int64 speed, int64 size)
    {
        if (_state[tokenId]._set == false) {
            sdfblend = 50;
            speed    = 0;
            size     = 75;
        } else {
            sdfblend = _state[tokenId].sdfblend;
            speed    = _state[tokenId].speed;
            size     = _state[tokenId].size;
        }
    }

    //-------------------------------------------------------------------------

    /**
     * Updates state of token, only owner or approved is allowed.
     * @param tokenId - token to update state on
     * @param sdfblend - sign distance field blend; 0-100
     * @param speed - speed; 0-200
     * @param size - size of shapes; 15-150
     *
     * Emits a {StateUpdated} event.
     */
    function updateState(uint256 tokenId, int64 sdfblend, int64 speed, int64 size)
        public
        approvedOrOwner(_msgSender(), tokenId)
    {
        require(0 <= sdfblend && sdfblend <= 100, "invalid sdfblend");
        require(0 <= speed && speed <= 200, "invalid speed");
        require(15 <= size && size <= 150, "invalid size");
        _state[tokenId].sdfblend = sdfblend;
        _state[tokenId].speed    = speed;
        _state[tokenId].size     = size;
        _state[tokenId]._set     = true;

        emit StateChange(msg.sender, tokenId, _state[tokenId]);
    }

}