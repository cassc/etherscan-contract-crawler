// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @dev Interface for the AssetWrapper contract. Only needed
 *      functions for rollover copied from V1.
*/
interface IAssetWrapper {
    function bundleERC721Holdings(uint256 bundleId, uint256 idx) external returns (address, uint256);

    function bundleERC1155Holdings(uint256 bundleId, uint256 idx) external returns (address, uint256, uint256);

    /**
     * @dev Withdraw all assets in the given bundle, returning them to the msg.sender
     *
     * Requirements:
     *
     * - The bundle with id `bundleId` must have been initialized with {initializeBundle}
     * - The bundle with id `bundleId` must be owned by or approved to msg.sender
     */
    function withdraw(uint256 bundleId) external;
}