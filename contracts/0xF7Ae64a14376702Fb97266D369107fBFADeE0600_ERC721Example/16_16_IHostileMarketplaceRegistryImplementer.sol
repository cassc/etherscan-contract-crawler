// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Required interface of a HostileMarketplaceRegistry implementing contract
 */
interface IHostileMarketplaceRegistryImplementer {
    /**
     * @dev sets the contract address for the desired deployed Hostile Marketplace Registry contract
     */
    function setBlocklistRegistry(address deployedRegistry) external;

    /**
     * @dev allows owner to toggle the use of hostile registry for their contract
     */
    function toggleMarketplaceBlockList(bool updatedRegistry) external;

    /**
     * @dev validates that the address provided is not on the block list.
     */
    function requireAddressIsNotBlocked(address addressToCheck) external;
}