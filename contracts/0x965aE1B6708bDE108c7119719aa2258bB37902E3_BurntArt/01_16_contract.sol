// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BurntArt is ERC721URIStorage, ERC2981, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint96 public royalty = 1000;

    constructor() ERC721("BurntArt", "ART") {
        _setDefaultRoyalty(msg.sender, royalty);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981)
    returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setRoyalty(uint96 _newRoyalty) public onlyOwner {
        royalty = _newRoyalty;
    }

    function mintNFT(address to, string memory uri) public onlyOwner {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, uri);
        _setTokenRoyalty(newItemId, to, royalty);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return super.tokenURI(tokenId);
    }
}