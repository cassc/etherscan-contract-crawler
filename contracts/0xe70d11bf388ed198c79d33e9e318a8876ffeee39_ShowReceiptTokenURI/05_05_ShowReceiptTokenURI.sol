// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/Strings.sol";

// This is a light "token URI" contract, to be used with a Fiefdom
contract ShowReceiptTokenURI is Ownable {
    string public baseURI;

    constructor(string memory _baseURI) {
        baseURI = _baseURI;
    }

    // Admin functions
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // View functions
    function tokenURI(uint256 tokenID) public view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenID)));
    }
}