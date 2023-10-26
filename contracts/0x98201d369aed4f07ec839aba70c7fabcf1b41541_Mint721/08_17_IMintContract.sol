// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IMetadataRenderer} from "create/interfaces/v1/IMetadataRenderer.sol";

interface IMintContractEvents {
    /// @notice Emitted when the royalty is updated.
    event RoyaltyUpdated(uint256 bps);
    /// @notice Emitted when a new mint module is added.
    event ModuleAdded(address module);
    /// @notice Emitted when a mint module is removed.
    event ModuleRemoved(address module);
    /// @notice Emitted when the metadata renderer is updated.
    event MetadataRendererUpdated(address renderer);
}

interface IMintContract is IMintContractEvents {
    /// @notice Mints tokens using approved mint modules.
    /// @param to The address receiving the minted tokens.
    /// @param quantity The quantity of tokens to mint.
    function mint(address to, uint256 quantity) external;

    /// @notice Mints tokens, callable only by the contract owner.
    /// @param to The address receiving the minted tokens.
    /// @param quantity The quantity of tokens to mint.
    function adminMint(address to, uint256 quantity) external;

    /// @notice Retrieves the payout recipient address for this mint contract.
    /// @return recipient address of the payout recipient.
    function payoutRecipient() external view returns (address recipient);

    /// @notice Returns the total number of tokens minted.
    /// @return total number of tokens minted.
    function totalMinted() external view returns (uint256 total);

    /// @notice Adds a new mint module as an approved minter.
    /// @dev Can only be executed by the owner of the contract.
    /// Must be approved in the MintModuleRegistry.
    /// @param mintModule The contract address of the mint module.
    function addMintModule(address mintModule) external;

    /// @notice Removes a mint module as an approved minter.
    /// @dev Can only be executed by the owner of the contract.
    /// @param mintModule The contract address of the mint module.
    function removeMintModule(address mintModule) external;

    /// @notice Returns whether a mint module is approved.
    /// @param mintModule The contract address of the mint module.
    /// @return isApproved Whether the mint module is approved.
    function isMintModuleApproved(address mintModule) external view returns (bool isApproved);

    /// @notice Updates configuration located in an external contract.
    /// @dev Can only be executed by the owner of the contract.
    /// The cardinality of `configurables` and `configData` must be the same.
    /// @param configurables The contract addresses to configure.
    /// @param configData The configuration data for the contracts.
    function updateExternalConfiguration(address[] calldata configurables, bytes[] calldata configData) external;

    /// @notice Sets the metadata renderer.
    /// @dev This will not request a metadata refresh. If needed, call `refreshMetadata`.
    /// @param renderer The new metadata renderer.
    function setMetadataRenderer(IMetadataRenderer renderer) external;

    /// @notice Returns the metadata renderer for this contract.
    /// @return metadataRenderer The metadata renderer.
    function metadataRenderer() external returns (IMetadataRenderer metadataRenderer);

    /// @notice Triggers a batch metadata update.
    function refreshMetadata() external;

    /// @notice Updates the royalty for this contract.
    /// @dev Can only be called by the contract owner.
    /// Emits a `RoyaltyUpdated` event.
    /// @param bps The new royalty.
    function setRoyalty(uint256 bps) external;

    /// @notice Returns the royalty for this contract.
    /// @return bps The royalty.
    function royaltyBps() external returns (uint256 bps);
}