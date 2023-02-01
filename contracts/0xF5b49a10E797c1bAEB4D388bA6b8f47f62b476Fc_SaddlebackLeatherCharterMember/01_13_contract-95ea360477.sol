// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract SaddlebackLeatherCharterMember is ERC721, ERC721URIStorage, Ownable {
    constructor() ERC721("Saddleback Leather Charter Member", "SLCM") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://bafybeigtomznyd7hkxsrnotmte6fyexooltefimjv5nf67hnaljjhby6c4.ipfs.nftstorage.link/charterMemberMetadata/";
    }

    function safeMint(address to, uint256 tokenId, string memory uri)
        public
        onlyOwner
    {
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