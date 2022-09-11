// SPDX-License-Identifier: BUSL-1.1
// omnisea-contracts v0.1

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../interfaces/IONFTCopy.sol";

contract ONFTCopy is IONFTCopy, ERC721URIStorage {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    function burn(uint256 tokenId) override external {
        _burn(tokenId);
    }

    function mint(address owner, uint256 tokenId, string memory tokenURI) override external {
        _safeMint(owner, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }
}