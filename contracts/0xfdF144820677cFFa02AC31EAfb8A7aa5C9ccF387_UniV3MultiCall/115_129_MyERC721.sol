// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MyERC721 is ERC721, ERC721Burnable, Ownable {
    mapping(uint256 => bool) public tokenIdTransferBlocked;
    address internal _owner;

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
        _transferOwnership(msg.sender);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function toggleBlockTransferTokenId(uint256 tokenId) public onlyOwner {
        tokenIdTransferBlocked[tokenId] = !tokenIdTransferBlocked[tokenId];
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(!tokenIdTransferBlocked[tokenId], "Token transfer blocked");
        super._transfer(from, to, tokenId);
    }
}