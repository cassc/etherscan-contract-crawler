// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ImmutableModule } from "../shared/ImmutableModule.sol";

/**
 * @title  VaultManagerRole , adds pausable capabilities, `onlyGovernor` can pause.
 * @notice Integrates to the `Nexus` contract resolves protocol module and role addresses.
 * For exmaple, the `Nexus` maintains who the protocol `Governor` is as well module addreesses
 * like the `Liquidator`.
 *
 * `VaultManagerRole` adds the `VaultManager` role that is trusted to set min and max parameters to protect
 * against sandwich attacks. The `VaultManager` can rebalance underlying vaults but can not
 * change the configuration of a vault. Basically, the `VaultManager` has to work within
 * the constraints of a vault's configuration. The `Governor` is the only account
 * that can change a vault's configuration.
 *
 * `VaultManagerRole` also adds pause capabilities that allows the protocol `Governor`
 * to pause all vault operations in an emergency.
 *
 * @author mStable
 * @dev     VERSION: 1.0
 *          DATE:    2021-02-24
 */
abstract contract VaultManagerRole is Pausable, ImmutableModule {
    /// @notice Trusted account that can perform vault operations that require parameters to protect against sandwich attacks.
    // For example, setting min or max amounts when rebalancing the underlyings of a vault.
    address public vaultManager;

    event SetVaultManager(address _vaultManager);

    /**
     * @param _nexus  Address of the `Nexus` contract that resolves protocol modules and roles.
     */
    constructor(address _nexus) ImmutableModule(_nexus) {}

    /**
     * @param _vaultManager Trusted account that can perform vault operations. eg rebalance.
     */
    function _initialize(address _vaultManager) internal virtual {
        vaultManager = _vaultManager;
    }

    modifier onlyVaultManager() {
        require(isVaultManager(msg.sender), "Only vault manager can execute");
        _;
    }

    /**
     * Checks if the specified `account` has the `VaultManager` role or not.
     * @param account Address to check if the `VaultManager` or not.
     * @return result true if the `account` is the `VaultManager`. false if not.
     */
    function isVaultManager(address account) public view returns (bool result) {
        result = vaultManager == account;
    }

    /**
     * @notice Called by the `Governor` to change the address of the `VaultManager` role.
     * Emits a `SetVaultManager` event.
     * @param _vaultManager Address that will take the `VaultManager` role.
     */
    function setVaultManager(address _vaultManager) external onlyGovernor {
        require(_vaultManager != address(0), "zero vault manager");
        require(vaultManager != _vaultManager, "already vault manager");

        vaultManager = _vaultManager;

        emit SetVaultManager(_vaultManager);
    }

    /**
     * @notice Called by the `Governor` to pause the contract.
     * Emits a `Paused` event.
     */
    function pause() external onlyGovernor whenNotPaused {
        _pause();
    }

    /**
     * @notice Called by the `Governor` to unpause the contract.
     * Emits a `Unpaused` event.
     */
    function unpause() external onlyGovernor whenPaused {
        _unpause();
    }
}