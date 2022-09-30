// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title Interface to the Vault Registry
 */
interface IVaultRegistry {
    /**************************************************************************/
    /* Events */
    /**************************************************************************/

    /**
     * @notice Emitted when a vault is registered
     * @param vault Vault address
     */
    event VaultRegistered(address indexed vault);

    /**
     * @notice Emitted when a vault is unregistered
     * @param vault Vault address
     */
    event VaultUnregistered(address indexed vault);

    /**************************************************************************/
    /* Primary API */
    /**************************************************************************/

    /**
     * @notice Register a vault
     *
     * Emits a {VaultRegistered} event.
     *
     * @param vault Vault address
     */
    function registerVault(address vault) external;

    /**
     * @notice Unregister a vault
     *
     * Emits a {VaultUnregistered} event.
     *
     * @param vault Vault address
     */
    function unregisterVault(address vault) external;

    /**
     * @notice Check if Vault is registered
     * @return True if registered, otherwise false
     */
    function isVaultRegistered(address vault) external view returns (bool);

    /**
     * @notice Get list of registered vaults
     * @return List of Vault addresses
     */
    function getVaultList() external view returns (address[] memory);

    /**
     * @notice Get count of registered vaults
     * @return Count of registered Vaults
     */
    function getVaultCount() external view returns (uint256);

    /**
     * @notice Get Vault at index
     * @param index Index
     * @return Vault address
     */
    function getVaultAt(uint256 index) external view returns (address);
}