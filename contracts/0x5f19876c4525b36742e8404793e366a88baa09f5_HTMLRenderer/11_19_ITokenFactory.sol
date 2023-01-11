//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ITokenFactory {
    error InvalidUpgrade(address impl);
    error NotDeployed(address impl);

    /// @notice Creates a new token contract with the given implementation and data
    function create(
        address tokenImpl,
        bytes calldata data
    ) external returns (address clone);

    /// @notice checks if an implementation is valid
    function isValidDeployment(address impl) external view returns (bool);

    /// @notice registers a new implementation
    function registerDeployment(address impl) external;

    /// @notice unregisters an implementation
    function unregisterDeployment(address impl) external;

    /// @notice checks if an upgrade is valid
    function isValidUpgrade(
        address prevImpl,
        address newImpl
    ) external returns (bool);

    /// @notice registers a new upgrade
    function registerUpgrade(address prevImpl, address newImpl) external;

    /// @notice unregisters an upgrade
    function unregisterUpgrade(address prevImpl, address newImpl) external;
}