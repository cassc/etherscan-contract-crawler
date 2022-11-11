// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TestMintPass is ERC721, Ownable {
    using Counters for Counters.Counter;

    uint256 private _tokenIdCounter;

    constructor() ERC721("TestNFT", "NFT") {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter++;
        _safeMint(to, tokenId);
    }

    function safeMintBatch(address to, uint256 quantity) public onlyOwner {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter += quantity;
        for (uint256 i = 0; i < quantity; i++) _safeMint(to, tokenId + i);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}