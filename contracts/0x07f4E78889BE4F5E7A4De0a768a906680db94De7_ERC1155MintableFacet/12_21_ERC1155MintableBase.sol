// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC1155Mintable} from "./../interfaces/IERC1155Mintable.sol";
import {ERC1155Storage} from "./../libraries/ERC1155Storage.sol";
import {AccessControlStorage} from "./../../../access/libraries/AccessControlStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC1155 Multi Token Standard, optional extension: Mintable (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC1155 (Multi Token Standard).
/// @dev Note: This contract requires AccessControl.
abstract contract ERC1155MintableBase is Context, IERC1155Mintable {
    using ERC1155Storage for ERC1155Storage.Layout;
    using AccessControlStorage for AccessControlStorage.Layout;

    bytes32 public constant MINTER_ROLE = "minter";

    /// @inheritdoc IERC1155Mintable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function safeMint(address to, uint256 id, uint256 value, bytes calldata data) external virtual override {
        address sender = _msgSender();
        AccessControlStorage.layout().enforceHasRole(MINTER_ROLE, sender);
        ERC1155Storage.layout().safeMint(sender, to, id, value, data);
    }

    /// @inheritdoc IERC1155Mintable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function safeBatchMint(address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external virtual override {
        address sender = _msgSender();
        AccessControlStorage.layout().enforceHasRole(MINTER_ROLE, sender);
        ERC1155Storage.layout().safeBatchMint(sender, to, ids, values, data);
    }
}