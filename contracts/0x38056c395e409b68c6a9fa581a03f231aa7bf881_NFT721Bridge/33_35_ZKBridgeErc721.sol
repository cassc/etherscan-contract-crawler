// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./BaseZKBridgeErc721.sol";

contract ZKBridgeErc721 is BaseZKBridgeErc721 {
    constructor(string memory _name, string memory _symbol) BaseZKBridgeErc721(_name, _symbol, msg.sender, false){

    }
}