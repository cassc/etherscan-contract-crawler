// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "ERC721.sol";

contract Viktoria is ERC721 {
    uint256 public tokenCounter;
    constructor () public ERC721 ("Viktoria", "VKA"){
        tokenCounter = 0;
    }

    function createCollectible(string memory tokenURI) public returns (uint256) {
        uint256 newItemId = tokenCounter;
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        tokenCounter = tokenCounter + 1;
        return newItemId;
    }

}