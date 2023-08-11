// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract DABUniques is ERC721, ERC721URIStorage, Ownable {
    
    uint256 private _tokenIds;
    
    constructor() ERC721("Digital Art Brokers Uniques", "DAB_INC") {}

    function mintDABUnique(string memory uri) external onlyOwner {
        _safeMint(msg.sender, _tokenIds);
        _setTokenURI(_tokenIds, uri);
        _tokenIds++;
    }

    function updateURI(uint256 tokenId, string memory uri) external onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    //-------------------------------------------------------------------------------------- OVERRIDE FUNCTIONS

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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}