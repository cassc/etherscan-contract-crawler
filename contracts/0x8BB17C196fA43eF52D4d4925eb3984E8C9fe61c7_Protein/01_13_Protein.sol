// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Protein is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public baseUrl = "https://raw.githubusercontent.com/avcdsld/code-as-art/main/protein/metadata.json?";

    constructor() ERC721("Protein", "PROTEIN") {}

    function safeMint(address to) public {
        address nextOwner = to;
        
        _tokenIdCounter.increment();
        uint256 currentId = _tokenIdCounter.current();
        if (currentId > 1) {
            for (uint256 tokenId = currentId - 1; tokenId > 0; tokenId--) {
                address currentOwner = ERC721.ownerOf(tokenId);
                _transfer(currentOwner, nextOwner, tokenId);
                nextOwner = currentOwner;
                if (tokenId == 1) break;
            }
        }

        _safeMint(nextOwner, currentId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUrl;
    }

    function setBaseURI(string memory _baseUrl) public onlyOwner {
        baseUrl = _baseUrl;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}