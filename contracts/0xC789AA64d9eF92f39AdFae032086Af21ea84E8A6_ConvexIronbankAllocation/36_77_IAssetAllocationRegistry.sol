// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IAssetAllocation} from "contracts/common/Imports.sol";

/**
 * @notice For managing a collection of `IAssetAllocation` contracts
 */
interface IAssetAllocationRegistry {
    /** @notice Log when an asset allocation is registered */
    event AssetAllocationRegistered(IAssetAllocation assetAllocation);

    /** @notice Log when an asset allocation is removed */
    event AssetAllocationRemoved(string name);

    /**
     * @notice Add a new asset allocation to the registry
     * @dev Should not allow duplicate asset allocations
     * @param assetAllocation The new asset allocation
     */
    function registerAssetAllocation(IAssetAllocation assetAllocation) external;

    /**
     * @notice Remove an asset allocation from the registry
     * @param name The name of the asset allocation (see `INameIdentifier`)
     */
    function removeAssetAllocation(string memory name) external;

    /**
     * @notice Check if multiple asset allocations are ALL registered
     * @param allocationNames An array of asset allocation names
     * @return `true` if every allocation is registered, otherwise `false`
     */
    function isAssetAllocationRegistered(string[] calldata allocationNames)
        external
        view
        returns (bool);

    /**
     * @notice Get the registered asset allocation with a given name
     * @param name The asset allocation name
     * @return The asset allocation
     */
    function getAssetAllocation(string calldata name)
        external
        view
        returns (IAssetAllocation);
}