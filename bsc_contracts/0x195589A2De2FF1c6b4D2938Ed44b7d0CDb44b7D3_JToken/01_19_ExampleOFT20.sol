// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/oft/OFT.sol";

/// @title A LayerZero OmnichainFungibleToken example using OFT
/// @notice Works in tandem with a BasedOFT. Use this to contract on for all NON-BASE chains. It burns tokens on send(), and mints on receive tokens form other chains.
contract JToken is OFT {
    constructor(
        address _layerZeroEndpoint, 
        string memory _name, 
        string memory _symbol
        ) OFT(_name, _symbol, _layerZeroEndpoint) {}
}