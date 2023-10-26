// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title IAssetRegistry
 * @notice Interface for the registry contract to provide compatibility between Pomace and Grappa
 */
interface IAssetRegistry {
    function assets(uint8 _id) external view returns (address addr, uint8 decimals);

    function assetIds(address _asset) external view returns (uint8 id);
}