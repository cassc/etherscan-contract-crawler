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
// Genetic Chain: Loomways
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

import "./GeneticChainMetadata.sol";

//------------------------------------------------------------------------------
// Loomways
//------------------------------------------------------------------------------

/**
 * @title Loomways
 * GeneticChain - Project #6 - Loomways
 */
contract Loomways is GeneticChainMetadata
{

    //-------------------------------------------------------------------------
    // structs
    //-------------------------------------------------------------------------

    struct ArtState {
        int64 flutA;
        int64 lnThk;
        bool moving;
        bool _set;
    }

    //-------------------------------------------------------------------------
    // events
    //-------------------------------------------------------------------------

    event StateChange(address indexed owner, uint256 tokenId, ArtState state);

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // token state
    mapping(uint256 => ArtState) _state;

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(
        IpfsAsset memory lib,
        string memory code_,
        string memory baseUri,
        uint256[3] memory tokenMax,
        uint256 seed,
        address proxyRegistryAddress)
        GeneticChainMetadata(
          lib,
          code_,
          baseUri,
          tokenMax,
          seed,
          proxyRegistryAddress)
    {
    }

    //-------------------------------------------------------------------------
    // state
    //-------------------------------------------------------------------------

    function state(uint256 tokenId)
        public
        view
        validTokenId(tokenId)
        returns (int64 flutA, int64 lnThk, bool moving)
    {
        if (_state[tokenId]._set == false) {
            flutA  = 0;
            lnThk  = 0;
            moving = true;
        } else {
            flutA  = _state[tokenId].flutA;
            lnThk  = _state[tokenId].lnThk;
            moving = _state[tokenId].moving;
        }
    }

    //-------------------------------------------------------------------------

    /**
     * Updates state of token, only owner or approved is allowed.
     * @param tokenId - token to update state on
     * @param flutA - flutter; -7-20
     * @param lnThk - line thinkness; -1-4
     * @param moving - animatied; true/false
     *
     * Emits a {StateUpdated} event.
     */
    function updateState(uint256 tokenId, int64 flutA, int64 lnThk, bool moving)
        public
        approvedOrOwner(_msgSender(), tokenId)
    {
        require(-7 <= flutA && flutA <= 20, "invalid flutA");
        require(-1 <= lnThk && lnThk <= 4, "invalid lnThk");
        _state[tokenId].flutA  = flutA;
        _state[tokenId].lnThk  = lnThk;
        _state[tokenId].moving = moving;
        _state[tokenId]._set   = true;

        emit StateChange(msg.sender, tokenId, _state[tokenId]);
    }

}