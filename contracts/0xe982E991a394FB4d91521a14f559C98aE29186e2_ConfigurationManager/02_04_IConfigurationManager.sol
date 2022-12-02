// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

/**
 * @title IConfigurationManager
 * @notice Allows contracts to read protocol-wide configuration modules
 * @author Pods Finance
 */
interface IConfigurationManager {
    event SetCap(address indexed target, uint256 value);
    event ParameterSet(address indexed target, bytes32 indexed name, uint256 value);
    event VaultAllowanceSet(address indexed oldVault, address indexed newVault);

    error ConfigurationManager__TargetCannotBeTheZeroAddress();
    error ConfigurationManager__NewVaultCannotBeTheZeroAddress();

    /**
     * @notice Set specific parameters to a contract or globally across multiple contracts.
     * @dev Use `address(0)` to set a global parameter.
     * @param target The contract address
     * @param name The parameter name
     * @param value The parameter value
     */
    function setParameter(
        address target,
        bytes32 name,
        uint256 value
    ) external;

    /**
     * @notice Retrieves the value of a parameter set to contract.
     * @param target The contract address
     * @param name The parameter name
     */
    function getParameter(address target, bytes32 name) external view returns (uint256);

    /**
     * @notice Retrieves the value of a parameter shared between multiple contracts.
     * @param name The parameter name
     */
    function getGlobalParameter(bytes32 name) external view returns (uint256);

    /**
     * @notice Defines a cap value to a contract.
     * @param target The contract address
     * @param value Cap amount
     */
    function setCap(address target, uint256 value) external;

    /**
     * @notice Get the value of a defined cap.
     * @dev Note that 0 cap means that the contract is not capped
     * @param target The contract address
     */
    function getCap(address target) external view returns (uint256);

    /**
     * @notice Sets the allowance to migrate to a `vault` address.
     * @param oldVault The current vault address
     * @param newVault The vault where assets are going to be migrated to
     */
    function setVaultMigration(address oldVault, address newVault) external;

    /**
     * @notice Returns the new Vault address.
     * @param oldVault The current vault address
     */
    function getVaultMigration(address oldVault) external view returns (address);
}