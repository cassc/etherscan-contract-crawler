// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";

contract MintableTestNFT is ERC721 {
    constructor (
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function burn(address from, uint256 tokenId) external {
        require(ownerOf(tokenId) == from, "NOT_OWNER");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        return "https://example.com/";
    }
}