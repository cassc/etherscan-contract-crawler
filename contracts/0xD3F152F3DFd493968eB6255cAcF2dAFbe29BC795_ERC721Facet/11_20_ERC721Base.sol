// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC721} from "./../interfaces/IERC721.sol";
import {IERC721Events} from "./../interfaces/IERC721Events.sol";
import {ERC721Storage} from "./../libraries/ERC721Storage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC721 Non-Fungible Token Standard (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC165 (Interface Detection Standard).
abstract contract ERC721Base is Context, IERC721, IERC721Events {
    using ERC721Storage for ERC721Storage.Layout;

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) external virtual override {
        ERC721Storage.layout().approve(_msgSender(), to, tokenId);
    }

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) external virtual override {
        ERC721Storage.layout().setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @inheritdoc IERC721
    function transferFrom(address from, address to, uint256 tokenId) external override {
        ERC721Storage.layout().transferFrom(_msgSender(), from, to, tokenId);
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual override {
        ERC721Storage.layout().safeTransferFrom(_msgSender(), from, to, tokenId);
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external virtual override {
        ERC721Storage.layout().safeTransferFrom(_msgSender(), from, to, tokenId, data);
    }

    /// @inheritdoc IERC721
    function balanceOf(address owner) external view override returns (uint256 balance) {
        return ERC721Storage.layout().balanceOf(owner);
    }

    /// @inheritdoc IERC721
    function ownerOf(uint256 tokenId) external view override returns (address tokenOwner) {
        return ERC721Storage.layout().ownerOf(tokenId);
    }

    /// @inheritdoc IERC721
    function getApproved(uint256 tokenId) external view override returns (address approved) {
        return ERC721Storage.layout().getApproved(tokenId);
    }

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator) external view override returns (bool approvedForAll) {
        return ERC721Storage.layout().isApprovedForAll(owner, operator);
    }
}