// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC721Metadata} from "./../interfaces/IERC721Metadata.sol";
import {ERC721Storage} from "./../libraries/ERC721Storage.sol";
import {ERC721ContractMetadataStorage} from "./../libraries/ERC721ContractMetadataStorage.sol";
import {TokenMetadataWithBaseURIStorage} from "./../../metadata/libraries/TokenMetadataWithBaseURIStorage.sol";
import {ContractOwnershipStorage} from "./../../../access/libraries/ContractOwnershipStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC721 Non-Fungible Token Standard (proxiable version), optional extension: Metadata (proxiable version).
/// @notice ERC721Metadata implementation where tokenURIs are the concatenation of a base metadata URI and the token identifier (decimal).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC721 (Non-Fungible Token Standard).
/// @dev Note: This contract requires ERC173 (Contract Ownership standard).
abstract contract ERC721MetadataWithBaseURIBase is Context, IERC721Metadata {
    using ERC721Storage for ERC721Storage.Layout;
    using ERC721ContractMetadataStorage for ERC721ContractMetadataStorage.Layout;
    using TokenMetadataWithBaseURIStorage for TokenMetadataWithBaseURIStorage.Layout;
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;

    /// @notice Emitted when the base token metadata URI is updated.
    /// @param baseMetadataURI The new base metadata URI.
    event BaseMetadataURISet(string baseMetadataURI);

    /// @notice Sets the base metadata URI.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Emits a {BaseMetadataURISet} event.
    /// @param baseURI The base metadata URI.
    function setBaseMetadataURI(string calldata baseURI) external {
        ContractOwnershipStorage.layout().enforceIsContractOwner(_msgSender());
        TokenMetadataWithBaseURIStorage.layout().setBaseMetadataURI(baseURI);
    }

    /// @notice Gets the base metadata URI.
    /// @return baseURI The base metadata URI.
    function baseMetadataURI() external view returns (string memory baseURI) {
        return TokenMetadataWithBaseURIStorage.layout().baseMetadataURI();
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
        return TokenMetadataWithBaseURIStorage.layout().tokenMetadataURI(tokenId);
    }
}