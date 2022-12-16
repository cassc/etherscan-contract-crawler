// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC721Deliverable} from "./../interfaces/IERC721Deliverable.sol";
import {ERC721Storage} from "./../libraries/ERC721Storage.sol";
import {AccessControlStorage} from "./../../../access/libraries/AccessControlStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC721 Non-Fungible Token Standard, optional extension: Deliverable (proxiable version).
/// @notice ERC721Deliverable implementation where burnt tokens can be minted again.
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC721 (Non-Fungible Token Standard).
/// @dev Note: This contract requires AccessControl.
abstract contract ERC721DeliverableBase is Context, IERC721Deliverable {
    using ERC721Storage for ERC721Storage.Layout;
    using AccessControlStorage for AccessControlStorage.Layout;

    // prevent variable name clash with public ERC721MintableBase.MINTER_ROLE
    bytes32 private constant _MINTER_ROLE = "minter";

    /// @inheritdoc IERC721Deliverable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function deliver(address[] calldata recipients, uint256[] calldata tokenIds) external virtual override {
        AccessControlStorage.layout().enforceHasRole(_MINTER_ROLE, _msgSender());
        ERC721Storage.layout().deliver(recipients, tokenIds);
    }
}