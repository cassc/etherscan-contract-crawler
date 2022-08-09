// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * @title   UpgradeBeaconInterface
 * @notice  UpgradeBeaconInterface contains all external function
 *          interfaces, events and errors related to the payable proxy.
 */
interface UpgradeBeaconInterface {
    /**
     * @dev Emit an event whenever the implementation has been upgraded.
     *
     * @param implementation  The new implementation address.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Revert with an error when attempting to call an operation
     *      while the caller is not the owner of the proxy.
     */
    error InvalidOwner();

    /**
     * @dev Revert with an error when attempting to set an non-contract
     *      address as the implementation.
     */
    error InvalidImplementation(address newImplementationAddress);

    /**
     * @notice Upgrades the beacon to a new implementation. Requires
     *         the caller must be the owner, and the new implementation
     *         must be a contract.
     *
     * @param newImplementationAddress The address to be set as the new
     *                                 implementation contract.
     */
    function upgradeTo(address newImplementationAddress) external;

    /**
     * @notice An external view function that returns the implementation.
     *
     * @return The address of the implementation.
     */
    function implementation() external view returns (address);
}