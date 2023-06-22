//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "./IExtensibleERC721Enumerable.sol";
// for opensea ownership
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ExtensibleERC721Enumerable is IExtensibleERC721Enumerable, ERC721A, Ownable {
    mapping (address => bool) public override isAdmin;
    bool public enabled = true;

    constructor() {
        isAdmin[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "ExtensibleERC721Enumerable: admins only");
        _;
    }

    modifier whenEnabled() {
        require(enabled, "ExtensibleERC721Enumerable: currently disabled");
        _;
    }

    function addAdmin(address addr) external override onlyAdmin {
        isAdmin[addr] = true;
    }

    function removeAdmin(address addr) external override onlyAdmin {
        delete isAdmin[addr];
    }

    function adminSetEnabled(bool e) external onlyAdmin {
        enabled = e;
    }

    function canAccessToken(address addr, uint tokenId) public view override returns (bool) {
        return isAdmin[addr] || ownerOf(tokenId) == addr || address(this) == addr;
    }

    function isApprovedForAll(address owner, address operator) public view virtual override(IERC721, ERC721A) returns (bool) {
        return isAdmin[operator] || super.isApprovedForAll(owner, operator);
    }

    function transferFrom(address from, address to, uint tokenId) public override(IERC721, ERC721A) whenEnabled {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId) public override(IERC721, ERC721A) whenEnabled {
        super.safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint tokenId, bytes calldata data) public override(IERC721, ERC721A) whenEnabled {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function adminBurn(uint tokenId) external override onlyAdmin whenEnabled {
        _burn(tokenId);
    }

    function adminTransfer(address from, address to, uint tokenId) external override whenEnabled {
        require(canAccessToken(msg.sender, tokenId), "ExtensibleERC721Enumerable: you are not allowed to perform this transfer");
        super.transferFrom(from, to, tokenId);
    }
}