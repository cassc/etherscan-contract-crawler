// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Creature is ERC721Tradable {

    string public baseURI = "https://api.cyber-hunter.com/token/";
    constructor(address _proxyRegistryAddress)
        ERC721Tradable("CyberHunter", "CBH",6666, _proxyRegistryAddress)
    {}

    function baseTokenURI() override public view returns (string memory) {
        return baseURI;
    }

    function setBaseTokenURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
}