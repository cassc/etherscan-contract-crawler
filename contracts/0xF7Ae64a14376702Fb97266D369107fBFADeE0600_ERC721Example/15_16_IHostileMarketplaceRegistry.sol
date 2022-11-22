// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Interface used to interact with deployed Hostile Registry Contract.
 */
interface IHostileMarketplaceRegistry {
    /**
     * @dev Used to call the address check method on the deployed contract.
     */
    function requireAddressIsNotBlocked(address addressToCheck) external;
}