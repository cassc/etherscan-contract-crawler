// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC1155MetadataURI} from "./../interfaces/IERC1155MetadataURI.sol";
import {ERC1155Storage} from "./../libraries/ERC1155Storage.sol";
import {TokenMetadataWithBaseURIStorage} from "./../../metadata/libraries/TokenMetadataWithBaseURIStorage.sol";
import {ContractOwnershipStorage} from "./../../../access/libraries/ContractOwnershipStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC1155 Multi Token Standard (proxiable version), optional extension: Metadata URI (proxiable version).
/// @notice ERC1155MetadataURI implementation where tokenURIs are the concatenation of a base metadata URI and the token identifier (decimal).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC1155 (Multi Token Standard).
/// @dev Note: This contract requires ERC173 (Contract Ownership standard).
abstract contract ERC1155MetadataURIWithBaseURIBase is Context, IERC1155MetadataURI {
    using ERC1155Storage for ERC1155Storage.Layout;
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

    /// @inheritdoc IERC1155MetadataURI
    function uri(uint256 id) external view override returns (string memory metadataURI) {
        return TokenMetadataWithBaseURIStorage.layout().tokenMetadataURI(id);
    }
}