// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "./ERC721Mint.sol";
import "../HasContractURI.sol";

abstract contract ERC721Core is 
    OwnableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721Mint,
    HasContractURI {

    // Base URI
    string public baseURI;

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165StorageUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721Mint) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        return super._beforeTokenTransfer(from, to, tokenId);
    }

    // These should be set by the Orderinbox admin only
    function _baseURI() internal view virtual override(ERC721Upgradeable) returns (string memory) {
        return baseURI;
    }

    function _setBaseURI(string memory baseUri) internal {
        baseURI = baseUri;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721URIStorageUpgradeable, ERC721Upgradeable) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721URIStorageUpgradeable, ERC721Upgradeable) onlyCreators(tokenId) {
        return super._burn(tokenId);
    }


    uint256[256] private __gap;
}