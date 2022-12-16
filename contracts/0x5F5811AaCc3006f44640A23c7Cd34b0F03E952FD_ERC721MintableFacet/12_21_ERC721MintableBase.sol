// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC721Mintable} from "./../interfaces/IERC721Mintable.sol";
import {ERC721Storage} from "./../libraries/ERC721Storage.sol";
import {AccessControlStorage} from "./../../../access/libraries/AccessControlStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC721 Non-Fungible Token Standard, optional extension: Mintable (proxiable version).
/// @notice ERC721Mintable implementation where burnt tokens can be minted again.
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC721 (Non-Fungible Token Standard).
/// @dev Note: This contract requires AccessControl.
abstract contract ERC721MintableBase is Context, IERC721Mintable {
    using ERC721Storage for ERC721Storage.Layout;
    using AccessControlStorage for AccessControlStorage.Layout;

    bytes32 public constant MINTER_ROLE = "minter";

    /// @inheritdoc IERC721Mintable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function mint(address to, uint256 tokenId) external virtual override {
        AccessControlStorage.layout().enforceHasRole(MINTER_ROLE, _msgSender());
        ERC721Storage.layout().mint(to, tokenId);
    }

    /// @inheritdoc IERC721Mintable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function safeMint(address to, uint256 tokenId, bytes calldata data) external virtual override {
        AccessControlStorage.layout().enforceHasRole(MINTER_ROLE, _msgSender());
        ERC721Storage.layout().safeMint(_msgSender(), to, tokenId, data);
    }

    /// @inheritdoc IERC721Mintable
    /// @dev Reverts if the sender does not have the 'minter' role.
    function batchMint(address to, uint256[] calldata tokenIds) external virtual override {
        AccessControlStorage.layout().enforceHasRole(MINTER_ROLE, _msgSender());
        ERC721Storage.layout().batchMint(to, tokenIds);
    }
}