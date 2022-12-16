// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC721BatchTransfer} from "./../interfaces/IERC721BatchTransfer.sol";
import {ERC721Storage} from "./../libraries/ERC721Storage.sol";
import {OperatorFiltererStorage} from "./../../royalty/libraries/OperatorFiltererStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC721 Non-Fungible Token Standard, optional extension: Batch Transfer with Operator Filterer (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC721 (Non-Fungible Token Standard).
abstract contract ERC721BatchTransferWithOperatorFiltererBase is Context, IERC721BatchTransfer {
    using ERC721Storage for ERC721Storage.Layout;
    using OperatorFiltererStorage for OperatorFiltererStorage.Layout;

    /// @inheritdoc IERC721BatchTransfer
    /// @dev Reverts with OperatorNotAllowed if the sender is not `from` and is not allowed by the operator registry.
    function batchTransferFrom(address from, address to, uint256[] calldata tokenIds) external virtual override {
        address sender = _msgSender();
        OperatorFiltererStorage.layout().requireAllowedOperatorForTransfer(sender, from);
        ERC721Storage.layout().batchTransferFrom(sender, from, to, tokenIds);
    }
}