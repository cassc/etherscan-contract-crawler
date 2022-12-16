// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC20Metadata} from "./../interfaces/IERC20Metadata.sol";
import {ERC20MetadataStorage} from "./../libraries/ERC20MetadataStorage.sol";
import {ContractOwnershipStorage} from "./../../../access/libraries/ContractOwnershipStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC20 Fungible Token Standard, optional extension: Metadata (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC20 (Fungible Token Standard).
/// @dev Note: This contract requires ERC173 (Contract Ownership standard).
abstract contract ERC20MetadataBase is Context, IERC20Metadata {
    using ERC20MetadataStorage for ERC20MetadataStorage.Layout;
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;

    /// @notice Sets the token URI.
    /// @dev Reverts if the sender is not the contract owner.
    /// @param uri The token URI.
    function setTokenURI(string calldata uri) external {
        ContractOwnershipStorage.layout().enforceIsContractOwner(_msgSender());
        ERC20MetadataStorage.layout().setTokenURI(uri);
    }

    /// @inheritdoc IERC20Metadata
    function tokenURI() external view override returns (string memory) {
        return ERC20MetadataStorage.layout().tokenURI();
    }
}