// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC1155MetadataURI} from "./../interfaces/IERC1155MetadataURI.sol";
import {ERC1155Storage} from "./../libraries/ERC1155Storage.sol";
import {TokenMetadataPerTokenStorage} from "./../../metadata/libraries/TokenMetadataPerTokenStorage.sol";
import {AccessControlStorage} from "./../../../access/libraries/AccessControlStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC1155 Multi Token Standard, optional extension: Metadata URI (proxiable version).
/// @notice ERC1155MetadataURI implementation where tokenURIs are set individually per token.
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC1155 (Multi Token Standard).
/// @dev Note: This contract requires AccessControl.
abstract contract ERC1155MetadataURIPerTokenBase is Context, IERC1155MetadataURI {
    using ERC1155Storage for ERC1155Storage.Layout;
    using TokenMetadataPerTokenStorage for TokenMetadataPerTokenStorage.Layout;
    using AccessControlStorage for AccessControlStorage.Layout;

    // prevent variable name clash with public ERC1155MintableBase.MINTER_ROLE
    bytes32 private constant _MINTER_ROLE = "minter";

    /// @notice Sets the metadata URI for a token.
    /// @dev Reverts if the sender does not have the 'minter' role.
    /// @param id The token identifier.
    /// @param metadataURI The token metadata URI.
    function setTokenURI(uint256 id, string calldata metadataURI) external {
        AccessControlStorage.layout().enforceHasRole(_MINTER_ROLE, _msgSender());
        TokenMetadataPerTokenStorage.layout().setTokenURI(id, metadataURI);
    }

    /// @notice Sets the metadata URIs for a batch of tokens.
    /// @dev Reverts if the sender does not have the 'minter' role.
    /// @param ids The token identifiers.
    /// @param metadataURIs The token metadata URIs.
    function batchSetTokenURI(uint256[] calldata ids, string[] calldata metadataURIs) external {
        AccessControlStorage.layout().enforceHasRole(_MINTER_ROLE, _msgSender());
        TokenMetadataPerTokenStorage.layout().batchSetTokenURI(ids, metadataURIs);
    }

    /// @inheritdoc IERC1155MetadataURI
    function uri(uint256 id) external view override returns (string memory metadataURI) {
        return TokenMetadataPerTokenStorage.layout().tokenMetadataURI(id);
    }
}