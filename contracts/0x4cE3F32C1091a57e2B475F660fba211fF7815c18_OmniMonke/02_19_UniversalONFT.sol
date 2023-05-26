// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8;

import ".././ONFT.sol";

/// @title Interface of the UniversalONFT standard
contract UniversalONFT is ONFT {
    uint public nextMintId;
    uint public maxMintId;
    uint public immutable startTimestamp;
    uint public immutable maxPerTx = 3;

    /// @notice Constructor for the UniversalONFT
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _layerZeroEndpoint handles message transmission across chains
    /// @param _startMintId the starting mint number on this chain
    /// @param _endMintId the max number of mints on this chain
    constructor(
        string memory _name,
        string memory _symbol,
        address _layerZeroEndpoint,
        uint _startMintId,
        uint _endMintId,
        uint _startTimestamp
    ) ONFT(_name, _symbol, _layerZeroEndpoint) {
        nextMintId = _startMintId;
        maxMintId = _endMintId;
        startTimestamp = _startTimestamp;
    }

    /// @notice Mint your ONFT
    function mint() external payable {
        require(nextMintId <= maxMintId, "ONFT: Max Mint limit reached");
        require(block.timestamp >= startTimestamp, "ONFT: Mint not started");
        require(balanceOf(msg.sender) < maxPerTx, "ONFT: Only 3 per wallet");

        uint newId = nextMintId;
        nextMintId++;

        _safeMint(msg.sender, newId);
    }
}