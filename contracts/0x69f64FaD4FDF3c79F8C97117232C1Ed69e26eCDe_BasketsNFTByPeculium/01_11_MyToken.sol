// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BasketsNFTByPeculium is ERC721, Ownable {
    constructor() ERC721("Baskets NFT By Peculium", "BASKET") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.saieve.io/api/v1/nfts/meta-data/";
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
}