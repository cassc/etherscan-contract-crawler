// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

enum TicketTypes {
    SILVER,
    GOLD
}

contract Ticket is ERC721AQueryable, ERC721ABurnable, Ownable {
    mapping(uint => TicketTypes) _tokenIdToTicketType;
    string private _contractUri;
    string private _baseUri;

    constructor() ERC721A("Ticket", "TKT") {
    }

    function mint(address accountAddress, TicketTypes ticketType) external onlyOwner {
        _tokenIdToTicketType[_nextTokenId()] = ticketType;
        _safeMint(accountAddress, 1);
    }

    function tokenTicketType(uint tokenId) external view returns (TicketTypes) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return _tokenIdToTicketType[tokenId];
    }

    function nextTokenId() external view returns (uint) {
        return _nextTokenId();
    }

    function contractURI() external view returns (string memory) {
        return _contractUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function setContractURI(string memory contractURI_) external onlyOwner {
        _contractUri = contractURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseUri = baseURI_;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(from == address(0) || to == address(0), "transfer not allowed");
    }
}