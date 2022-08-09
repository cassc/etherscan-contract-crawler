// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8;

import "../ONFT721.sol";

/// @title Interface of the UniversalONFT standard
contract UniversalONFT721 is ONFT721 {
    uint public nextMintId;
    uint public maxMintId;

    event Sign(address to, bytes signature, uint tokenId);
    /// @notice Constructor for the UniversalONFT
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _layerZeroEndpoint handles message transmission across chains
    /// @param _startMintId the starting mint number on this chain
    /// @param _endMintId the max number of mints on this chain
    constructor(string memory _name, string memory _symbol, address _layerZeroEndpoint, uint _startMintId, uint _endMintId) ONFT721(_name, _symbol, _layerZeroEndpoint) {
        nextMintId = _startMintId;
        maxMintId = _endMintId;
    }

    /// @notice Mint your ONFT
    function safeMint(address _to, bytes memory signature) internal {
        require(nextMintId <= maxMintId, "ONFT: Max Mint limit reached");

        uint newId = nextMintId;
        nextMintId++;

        _safeMint(_to, newId);

        emit Sign(_to, signature, newId);
    }

    function _setMaxMintId(uint _endMaxId) internal {
        maxMintId = _endMaxId;
    }
}