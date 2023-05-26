// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GeneticChainMetadata.sol";

/**
 * @title Spiral Frequenceies
 * GeneticChain - Project #1 - Spiral Frequencies
 */
contract SpiralFrequencies is GeneticChainMetadata {

    struct ArtState {
        string t;
        uint256 speed;
    }

    // Token State
    mapping(uint256 => ArtState) _state;

    // StateChange
    event StateChange(address indexed owner, uint256 tokenId, ArtState state);

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
        GeneticChainMetadata(
          name_,
          symbol_,
          projectId_,
          artist_,
          description_,
          code_,
          baseUri_,
          publicMax_,
          privateMax_,
          seed_,
          proxyRegistryAddress)
    {
    }

    function state(uint256 tokenId)
        public
        view
        validTokenId(tokenId)
        returns (string memory t, uint256 speed)
    {
        if (bytes(_state[tokenId].t).length == 0) {
            t      = "0";
            speed  = 5;
        } else {
            t      = _state[tokenId].t;
            speed  = _state[tokenId].speed;
        }
    }

    /**
     * Updates state of token, only owner or approved is allowed.
     * @param tokenId - token to update state on
     * @param t - float encoded as string
     * @param speed - speed to run at; 0-10
     *
     * Emits a {StateUpdated} event.
     */
    function updateState(uint256 tokenId, string memory t, uint256 speed)
        public
        approvedOrOwner(_msgSender(), tokenId)
    {
        require(0 <= speed && speed <= 10, "SpiralFrequencies: Invalid speed only 0-10 allowed.");
        _state[tokenId].t     = t;
        _state[tokenId].speed = speed;

        emit StateChange(msg.sender, tokenId, _state[tokenId]);
    }

}