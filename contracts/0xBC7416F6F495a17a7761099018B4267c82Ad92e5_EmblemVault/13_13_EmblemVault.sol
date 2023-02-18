// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EmblemVault is ERC721, ERC721URIStorage, Ownable {
    constructor() ERC721("Emblem Vault V2", "Emblem.pro") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.emblemvault.io/s:evmetadata/meta/";
    }

    function mint(uint256 tokenId) public onlyOwner {
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, Strings.toString(tokenId));
    }

    function batchMint(uint256[] memory tokenIds) public onlyOwner {
        for (uint i = 0; i < tokenIds.length; i++ ) {
            _safeMint(msg.sender, tokenIds[i]);
            _setTokenURI(tokenIds[i], Strings.toString(tokenIds[i]));
        }
    }

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