// SPDX-License-Identifier: LGPL-3.0-or-later 

pragma solidity ^0.8.17;

import '@ERC721A/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract HANDOFTHANOS is ERC721A, ERC2981, Ownable {

    error MaxSupplyError();
    error URIQueryForNonexistentTokenID();

    uint256 public maxSupply = 1;
    string private _tokenbaseURI = 'http://yummydog.yummy-crypto.com/meta/hand';

    constructor() ERC721A("HANDOFTHANOS", "YUMMY: Hand of Thanos") {
    }

    function mintHand(address to) external onlyOwner {
        if (totalSupply() + 1 > maxSupply) revert MaxSupplyError();

        _mint(to, 1);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenbaseURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _tokenbaseURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentTokenID();

        return _tokenbaseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}