// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./AbsERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract TreumERC721 is AbsERC721, ERC721URIStorage, Ownable {
    constructor(string memory name, string memory symbol) AbsERC721(name, symbol, "") {}

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(AbsERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721URIStorage, ERC721) {
        ERC721URIStorage._burn(tokenId);
    }

    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override(AbsERC721, ERC721) returns (string memory) {
        return AbsERC721._baseURI();
    }

    function setBaseURI(string memory baseURI) external virtual override onlyOwner {
        _setBaseURI(baseURI);
    }

    function mintWithTokenURI(
        address to,
        uint256 tokenId,
        string memory uri
    ) external onlyOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function isMinter(address account) external view returns (bool) {
        return owner() == account;
    }
}