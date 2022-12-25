// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

interface IUniswapPathChecker {
    /// @dev Returns whether a specified token is a registered connector token
    /// @param token Token to check
    function isConnector(address token) external view returns (bool);

    /// @dev Performs sanity checks on a Uniswap V2 path (result is returned as `valid`) and returns input/output tokens
    /// @param path UniswapV2 swap path
    function parseUniV2Path(address[] memory path)
        external
        view
        returns (
            bool valid,
            address tokenIn,
            address tokenOut
        );

    /// @dev Performs sanity checks on a Uniswap V3 path (result is returned as `valid`) and returns input/output tokens
    /// @param path UniswapV3 bytes-encoded path
    function parseUniV3Path(bytes memory path)
        external
        view
        returns (
            bool valid,
            address tokenIn,
            address tokenOut
        );
}