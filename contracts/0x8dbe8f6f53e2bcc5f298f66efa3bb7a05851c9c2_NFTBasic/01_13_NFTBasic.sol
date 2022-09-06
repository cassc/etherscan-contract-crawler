// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTBasic is ERC721Enumerable, Ownable {

    mapping(uint256 => string) tokenURIs;

    constructor() ERC721("Ownership Access Token", "OAT") {}

    function mint(address to, string memory uri, uint256 tokenId) public onlyOwner {
        require(keccak256(abi.encode(tokenURIs[tokenId])) == keccak256(abi.encode("")),
                "NFTBasic: Already minted");
        tokenURIs[tokenId] = uri;
        _mint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return tokenURIs[tokenId];
    }
}