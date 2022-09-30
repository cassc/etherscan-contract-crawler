// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IVaultRegistry.sol";

/**
 * @title Vault Registry
 */
contract VaultRegistry is Ownable, IVaultRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.0";

    /**************************************************************************/
    /* State */
    /**************************************************************************/

    /**
     * @dev Vault registry
     */
    EnumerableSet.AddressSet private _registry;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice VaultRegistry constructor
     */
    constructor() {}

    /**************************************************************************/
    /* Primary API */
    /**************************************************************************/

    /**
     * @inheritdoc IVaultRegistry
     */
    function registerVault(address vault) external onlyOwner {
        if (_registry.add(vault)) {
            emit VaultRegistered(vault);
        }
    }

    /**
     * @inheritdoc IVaultRegistry
     */
    function unregisterVault(address vault) external onlyOwner {
        if (_registry.remove(vault)) {
            emit VaultUnregistered(vault);
        }
    }

    /**
     * @inheritdoc IVaultRegistry
     */
    function isVaultRegistered(address vault) external view returns (bool) {
        return _registry.contains(vault);
    }

    /**
     * @inheritdoc IVaultRegistry
     */
    function getVaultList() external view returns (address[] memory) {
        return _registry.values();
    }

    /**
     * @inheritdoc IVaultRegistry
     */
    function getVaultCount() external view returns (uint256) {
        return _registry.length();
    }

    /**
     * @inheritdoc IVaultRegistry
     */
    function getVaultAt(uint256 index) external view returns (address) {
        return _registry.at(index);
    }
}