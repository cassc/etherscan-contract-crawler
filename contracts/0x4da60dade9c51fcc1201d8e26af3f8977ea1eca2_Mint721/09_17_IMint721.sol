// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Mint721Configuration} from "./Mint721Configuration.sol";
import {IMetadataRenderer} from "./IMetadataRenderer.sol";

interface IMint721 {
    /// @notice Initializes a new Mint721 contract with the provided configuration.
    /// @dev `mintModules` and `mintModulesData` must have the same cardinality.
    /// @param configuration The configuration data.
    /// @param mintModuleRegistry The mint module registry.
    /// @param metadataRenderer The metadata renderer.
    /// @param metadataRendererConfig The configuration data for the metadata renderer, or none if not required.
    /// @param mintModules The initial approved mint modules.
    /// @param mintModuleData The configuration data for the mint modules.
    /// @param creator The creator of the contract.
    function initialize(
        Mint721Configuration calldata configuration,
        address mintModuleRegistry,
        IMetadataRenderer metadataRenderer,
        bytes calldata metadataRendererConfig,
        address[] calldata mintModules,
        bytes[] calldata mintModuleData,
        address creator
    ) external;
}