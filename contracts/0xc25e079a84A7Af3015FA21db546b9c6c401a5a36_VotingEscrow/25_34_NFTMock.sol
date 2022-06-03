// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/INFT.sol";

contract NFTMock is ERC721, Ownable, INFT {
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        // Empty
    }

    function balanceOf(address owner) public view override(ERC721, INFT) returns (uint256 balance) {
        return ERC721.balanceOf(owner);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, INFT) {
        ERC721.safeTransferFrom(from, to, tokenId);
    }

    function mint(
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override onlyOwner {
        _safeMint(to, tokenId, data);
    }

    function mintBatch(
        address to,
        uint256[] calldata tokenIds,
        bytes calldata data
    ) external override onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            _safeMint(to, tokenIds[i], data);
        }
    }

    function burn(
        uint256 tokenId,
        uint256,
        bytes32
    ) external override {
        _burn(tokenId);
    }
}