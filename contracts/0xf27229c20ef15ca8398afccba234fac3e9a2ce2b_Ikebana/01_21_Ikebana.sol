// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./GeneticChainMetadata.sol";

/**
 * @title Ikebana
 * GeneticChain - Project #5 - Ikebana
 */
contract Ikebana is GeneticChainMetadata {

    struct ArtState {
        uint64 cubesize;
        uint64 speed;
        uint128 offset;
    }

    // Token State
    mapping(uint256 => bool) _set;
    mapping(uint256 => ArtState) _state;

    // StateChange
    event StateChange(address indexed owner, uint256 tokenId, ArtState state);

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

    function state(uint256 tokenId)
        public
        view
        validTokenId(tokenId)
        returns (uint64 cubesize, uint64 speed, uint128 offset)
    {
        if (_set[tokenId] == false) {
            cubesize = 60;
            speed    = 10;
            offset   = 50;
        } else {
            cubesize = _state[tokenId].cubesize;
            speed    = _state[tokenId].speed;
            offset   = _state[tokenId].offset;
        }
    }

    /**
     * Updates state of token, only owner or approved is allowed.
     * @param tokenId - token to update state on
     * @param cubesize - size of cubes; 10-100
     * @param speed - speed to run at; 5-50
     * @param offset - camera offset; 10-200
     *
     * Emits a {StateUpdated} event.
     */
    function updateState(uint256 tokenId, uint64 cubesize, uint64 speed, uint128 offset)
        public
        approvedOrOwner(_msgSender(), tokenId)
    {
        require(10 <= cubesize && cubesize <= 100, "invalid cubesize, 10-100 allowed.");
        require(5 <= speed && speed <= 50, "invalid speed, 5-50 allowed.");
        require(10 <= offset && offset <= 200, "invalid offset, 10-200 allowed.");
        _set[tokenId]            = true;
        _state[tokenId].cubesize = cubesize;
        _state[tokenId].speed    = speed;
        _state[tokenId].offset   = offset;

        emit StateChange(msg.sender, tokenId, _state[tokenId]);
    }

}