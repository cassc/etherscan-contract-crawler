// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

interface IUniswapConnectorCheckerExceptions {
    /// @notice Thrown when trying to create a connector checker with more connectors than allowed
    error TooManyConnectorsException();
}

interface IUniswapConnectorChecker is IUniswapConnectorCheckerExceptions {
    /// @notice Returns true if given token is a registered connector token
    function isConnector(address token) external view returns (bool);

    /// @notice Returns the array of registered connector tokens
    function getConnectors() external view returns (address[] memory connectors);
}