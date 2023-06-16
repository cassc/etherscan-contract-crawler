// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {IAdapter} from "../IAdapter.sol";

interface ILidoV1AdapterEvents {
    /// @notice Emitted when configurator sets new deposit limit
    event NewLimit(uint256 _limit);
}

interface ILidoV1AdapterExceptions {
    /// @notice Thrown when trying to stake more than the current limit
    error LimitIsOverException();
}

/// @title Lido V1 adapter interface
/// @notice Implements logic for interacting with the Lido contract through the gateway
interface ILidoV1Adapter is IAdapter, ILidoV1AdapterEvents, ILidoV1AdapterExceptions {
    /// @notice Address of WETH
    function weth() external view returns (address);

    /// @notice Address of the Lido contract
    function stETH() external view returns (address);

    /// @notice Collateral token mask of WETH in the credit manager
    function wethTokenMask() external view returns (uint256);

    /// @notice Collateral token mask of stETH in the credit manager
    function stETHTokenMask() external view returns (uint256);

    /// @notice Address of Gearbox treasury
    function treasury() external view returns (address);

    /// @notice The amount of WETH that can be deposited through this adapter
    function limit() external view returns (uint256);

    /// @notice Stakes given amount of WETH in Lido via Gateway
    /// @param amount Amount of WETH to deposit
    /// @dev The referral address is set to Gearbox treasury
    function submit(uint256 amount) external;

    /// @notice Stakes the entire balance of WETH in Lido via Gateway, disables WETH
    /// @dev The referral address is set to Gearbox treasury
    function submitAll() external;

    /// @notice Set a new deposit limit
    /// @param _limit New value for the limit
    function setLimit(uint256 _limit) external;
}