// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IYearnVaultRegistry
 * @author Babylon Finance
 *
 * Interface for interacting with all the pickle jars
 */
interface IYearnVaultRegistry {
    /* ============ Functions ============ */

    function updateVaults(address[] calldata _jars, bool[] calldata _values) external;

    /* ============ View Functions ============ */

    function vaults(address _vaultAddress) external view returns (bool);

    function getAllVaults() external view returns (address[] memory);
}