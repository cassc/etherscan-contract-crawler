// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC721} from "./../interfaces/IERC721.sol";
import {IERC721Events} from "./../interfaces/IERC721Events.sol";
import {ERC721Storage} from "./../libraries/ERC721Storage.sol";
import {OperatorFiltererStorage} from "./../../royalty/libraries/OperatorFiltererStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC721 Non-Fungible Token Standard with Operator Filterer (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC165 (Interface Detection Standard).
/// @dev Note: This contract requires OperatorFilterer.
abstract contract ERC721WithOperatorFiltererBase is Context, IERC721, IERC721Events {
    using ERC721Storage for ERC721Storage.Layout;
    using OperatorFiltererStorage for OperatorFiltererStorage.Layout;

    /// @inheritdoc IERC721
    /// @dev Reverts with OperatorNotAllowed if `to` is not the zero address and is not allowed by the operator registry.
    function approve(address to, uint256 tokenId) external virtual override {
        if (to != address(0)) {
            OperatorFiltererStorage.layout().requireAllowedOperatorForApproval(to);
        }
        ERC721Storage.layout().approve(_msgSender(), to, tokenId);
    }

    /// @inheritdoc IERC721
    /// @dev Reverts with OperatorNotAllowed if `approved` is true and `operator` is not allowed by the operator registry.
    function setApprovalForAll(address operator, bool approved) external virtual override {
        if (approved) {
            OperatorFiltererStorage.layout().requireAllowedOperatorForApproval(operator);
        }
        ERC721Storage.layout().setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @inheritdoc IERC721
    /// @dev Reverts with OperatorNotAllowed if the sender is not `from` and is not allowed by the operator registry.
    function transferFrom(address from, address to, uint256 tokenId) external override {
        address sender = _msgSender();
        OperatorFiltererStorage.layout().requireAllowedOperatorForTransfer(sender, from);
        ERC721Storage.layout().transferFrom(sender, from, to, tokenId);
    }

    /// @inheritdoc IERC721
    /// @dev Reverts with OperatorNotAllowed if the sender is not `from` and is not allowed by the operator registry.
    function safeTransferFrom(address from, address to, uint256 tokenId) external virtual override {
        address sender = _msgSender();
        OperatorFiltererStorage.layout().requireAllowedOperatorForTransfer(sender, from);
        ERC721Storage.layout().safeTransferFrom(sender, from, to, tokenId);
    }

    /// @inheritdoc IERC721
    /// @dev Reverts with OperatorNotAllowed if the sender is not `from` and is not allowed by the operator registry.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external virtual override {
        address sender = _msgSender();
        OperatorFiltererStorage.layout().requireAllowedOperatorForTransfer(sender, from);
        ERC721Storage.layout().safeTransferFrom(sender, from, to, tokenId, data);
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