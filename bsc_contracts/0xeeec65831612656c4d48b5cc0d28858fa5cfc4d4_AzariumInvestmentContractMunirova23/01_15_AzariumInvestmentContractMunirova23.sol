// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/Counters.sol";

contract AzariumInvestmentContractMunirova23 is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor()
        ERC721("Azarium Investment Contract Munirova 23", "AZ-NFT-23")
    {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://gateway.pinata.cloud";
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}