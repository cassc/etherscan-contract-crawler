// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IMintModuleRegistryEvents {
    /// @notice Emitted when a new module is registered.
    /// @param module The contract address of the new mint module.
    event ModuleAdded(address indexed module);

    /// @notice Emitted when a module is unregistered.
    /// @param module The address of mint module being removed.
    event ModuleRemoved(address indexed module);
}

interface IMintModuleRegistry is IMintModuleRegistryEvents {
    error AlreadyRegistered();
    error NotRegistered();
    error InvalidAddress();

    /// @notice Registers a new mint module.
    /// @dev Can only be executed by protocol admin. Raises `InvalidAddress` if `mintModule` is the zero address.
    /// Raises `AlreadyRegistered` if the module is already registered.
    /// @param mintModule The contract address of the mint module.
    function addModule(address mintModule) external;

    /// @notice Unregisters a mint module.
    /// @dev Can only be executed by protocol admin. Raises `InvalidAddress` if `mintModule` is the zero address.
    /// Raises `NotRegistered` if the module isn't currently registered.
    /// @param mintModule The contract address of the mint module.
    function removeModule(address mintModule) external;

    /// @notice Checks if a mint module is registered.
    /// @param mintModule The contract address of the mint module.
    /// @return isModuleRegistered True if the module is registered, false otherwise.
    function isRegistered(address mintModule) external view returns (bool isModuleRegistered);

    /// @notice Checks if the mint module is registered.
    /// @dev Reverts with `NotRegistered` if the module isn't registered.
    /// @param mintModule The contract address of the mint module.
    function checkModule(address mintModule) external;
}