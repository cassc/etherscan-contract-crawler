// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is
    ERC721,
    Ownable,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable
{
    constructor() ERC721("NFT", "NFT") {}

    bool public initialized;

    /// @dev Can only be called once
    function mint(string memory uri1, string memory uri2, string memory uri3) public onlyOwner {
        require(initialized == false);
        initialized = true;
        safeMint(1, uri1);
        safeMint(2, uri2);
        safeMint(3, uri3);
    }

    function safeMint(uint256 tokenId, string memory uri) private {
        _safeMint(owner(), tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {revert();}
    fallback() external payable {revert();}
}