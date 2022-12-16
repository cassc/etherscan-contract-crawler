// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC1155} from "./../interfaces/IERC1155.sol";
import {ERC1155Storage} from "./../libraries/ERC1155Storage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC1155 Multi Token Standard (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC165 (Interface Detection Standard).
abstract contract ERC1155Base is Context, IERC1155 {
    using ERC1155Storage for ERC1155Storage.Layout;

    /// @inheritdoc IERC1155
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external virtual override {
        ERC1155Storage.layout().safeTransferFrom(_msgSender(), from, to, id, value, data);
    }

    /// @inheritdoc IERC1155
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override {
        ERC1155Storage.layout().safeBatchTransferFrom(_msgSender(), from, to, ids, values, data);
    }

    /// @inheritdoc IERC1155
    function setApprovalForAll(address operator, bool approved) external virtual override {
        ERC1155Storage.layout().setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @inheritdoc IERC1155
    function isApprovedForAll(address owner, address operator) external view override returns (bool approvedForAll) {
        return ERC1155Storage.layout().isApprovedForAll(owner, operator);
    }

    /// @inheritdoc IERC1155
    function balanceOf(address owner, uint256 id) external view virtual override returns (uint256 balance) {
        return ERC1155Storage.layout().balanceOf(owner, id);
    }

    /// @inheritdoc IERC1155
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view virtual override returns (uint256[] memory balances) {
        return ERC1155Storage.layout().balanceOfBatch(owners, ids);
    }
}