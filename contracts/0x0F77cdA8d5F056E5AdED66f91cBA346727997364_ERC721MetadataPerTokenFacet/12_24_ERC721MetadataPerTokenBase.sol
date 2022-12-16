// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC721Metadata} from "./../interfaces/IERC721Metadata.sol";
import {ERC721Storage} from "./../libraries/ERC721Storage.sol";
import {ERC721ContractMetadataStorage} from "./../libraries/ERC721ContractMetadataStorage.sol";
import {TokenMetadataPerTokenStorage} from "./../../metadata/libraries/TokenMetadataPerTokenStorage.sol";
import {AccessControlStorage} from "./../../../access/libraries/AccessControlStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC721 Non-Fungible Token Standard, optional extension: Metadata (proxiable version).
/// @notice ERC721Metadata implementation where tokenURIs are set individually per token.
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC721 (Non-Fungible Token Standard).
/// @dev Note: This contract requires AccessControl.
abstract contract ERC721MetadataPerTokenBase is Context, IERC721Metadata {
    using ERC721Storage for ERC721Storage.Layout;
    using ERC721ContractMetadataStorage for ERC721ContractMetadataStorage.Layout;
    using TokenMetadataPerTokenStorage for TokenMetadataPerTokenStorage.Layout;
    using AccessControlStorage for AccessControlStorage.Layout;

    // prevent variable name clash with public ERC721Mintable(Once)Base.MINTER_ROLE
    bytes32 private constant _MINTER_ROLE = "minter";

    /// @notice Sets the metadata URI for a token.
    /// @dev Reverts if the sender does not have the 'minter' role.
    /// @param tokenId The token identifier.
    /// @param uri The token metadata URI.
    function setTokenURI(uint256 tokenId, string calldata uri) external {
        AccessControlStorage.layout().enforceHasRole(_MINTER_ROLE, _msgSender());
        TokenMetadataPerTokenStorage.layout().setTokenURI(tokenId, uri);
    }

    /// @notice Sets the metadata URIs for a batch of tokens.
    /// @dev Reverts if the sender does not have the 'minter' role.
    /// @param tokenIds The token identifiers.
    /// @param uris The token metadata URIs.
    function batchSetTokenURI(uint256[] calldata tokenIds, string[] calldata uris) external {
        AccessControlStorage.layout().enforceHasRole(_MINTER_ROLE, _msgSender());
        TokenMetadataPerTokenStorage.layout().batchSetTokenURI(tokenIds, uris);
    }

    /// @inheritdoc IERC721Metadata
    function name() external view override returns (string memory tokenName) {
        return ERC721ContractMetadataStorage.layout().name();
    }

    /// @inheritdoc IERC721Metadata
    function symbol() external view override returns (string memory tokenSymbol) {
        return ERC721ContractMetadataStorage.layout().symbol();
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) external view override returns (string memory uri) {
        ERC721Storage.layout().ownerOf(tokenId); // reverts if the token does not exist
        return TokenMetadataPerTokenStorage.layout().tokenMetadataURI(tokenId);
    }
}