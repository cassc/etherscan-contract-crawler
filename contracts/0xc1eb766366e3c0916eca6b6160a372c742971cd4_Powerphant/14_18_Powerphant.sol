// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Powerphant
 * Powerphant - 
 */
contract Powerphant is ERC721Tradable {
    // Base token URI
    string private _baseTokenURI;

    constructor()
        ERC721Tradable("Powerphant", "PwP")
    {
        _baseTokenURI = "ipfs://bafybeibfqmqlivk2w23rkakssnj265ul7lhn6mdgdf57x7ubkd5vvslwae/";
    }

    function baseTokenURI() override public view returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory _uri) public onlyOwner {
        _baseTokenURI = _uri;
    }
}