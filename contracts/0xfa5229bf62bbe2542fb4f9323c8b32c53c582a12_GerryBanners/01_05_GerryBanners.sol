// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "erc721a/ERC721A.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract GerryBanners is ERC721A, Ownable {
    mapping(uint256 => string) public tokenURIs;

    constructor(address owner_)
        ERC721A("Gerry Banners", "GERRY")
    {
        require(owner_ != address(0));
        _transferOwnership(owner_);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return tokenURIs[tokenId];
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _safeMint(to, amount);
    }

    function setTokenURI(uint256 tokenId, string calldata tokenURI_)
        public
        onlyOwner
    {
        tokenURIs[tokenId] = tokenURI_;
    }
}