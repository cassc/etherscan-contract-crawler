// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC721BatchTransfer} from "./../interfaces/IERC721BatchTransfer.sol";
import {ERC721Storage} from "./../libraries/ERC721Storage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC721 Non-Fungible Token Standard, optional extension: Batch Transfer (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC721 (Non-Fungible Token Standard).
abstract contract ERC721BatchTransferBase is Context, IERC721BatchTransfer {
    using ERC721Storage for ERC721Storage.Layout;

    /// @inheritdoc IERC721BatchTransfer
    function batchTransferFrom(address from, address to, uint256[] calldata tokenIds) external virtual override {
        ERC721Storage.layout().batchTransferFrom(_msgSender(), from, to, tokenIds);
    }
}