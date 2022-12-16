// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC1155Deliverable} from "./../interfaces/IERC1155Deliverable.sol";
import {ERC1155Storage} from "./../libraries/ERC1155Storage.sol";
import {AccessControlStorage} from "./../../../access/libraries/AccessControlStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC1155 Multi Token Standard, optional extension: Deliverable (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC1155 (Multi Token Standard).
/// @dev Note: This contract requires AccessControl.
abstract contract ERC1155DeliverableBase is Context, IERC1155Deliverable {
    using ERC1155Storage for ERC1155Storage.Layout;
    using AccessControlStorage for AccessControlStorage.Layout;

    // prevent variable name clash with public ERC1155MintableBase.MINTER_ROLE
    bytes32 private constant _MINTER_ROLE = "minter";

    /// @inheritdoc IERC1155Deliverable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function safeDeliver(
        address[] calldata recipients,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external virtual override {
        address sender = _msgSender();
        AccessControlStorage.layout().enforceHasRole(_MINTER_ROLE, sender);
        ERC1155Storage.layout().safeDeliver(sender, recipients, ids, values, data);
    }
}