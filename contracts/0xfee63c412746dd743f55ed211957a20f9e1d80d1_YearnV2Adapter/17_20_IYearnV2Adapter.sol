// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.17;

import {IAdapter} from "../IAdapter.sol";

/// @title Yearn V2 Vault adapter interface
/// @notice Implements logic allowing CAs to deposit into Yearn vaults
interface IYearnV2Adapter is IAdapter {
    /// @notice Vault's underlying token address
    function token() external view returns (address);

    /// @notice Collateral token mask of underlying token in the credit manager
    function tokenMask() external view returns (uint256);

    /// @notice Collateral token mask of eToken in the credit manager
    function yTokenMask() external view returns (uint256);

    /// @notice Deposit the entire balance of underlying tokens into the vault, disables underlying
    function deposit() external;

    /// @notice Deposit given amount of underlying tokens into the vault
    /// @param amount Amount of underlying tokens to deposit
    function deposit(uint256 amount) external;

    /// @notice Deposit given amount of underlying tokens into the vault
    /// @param amount Amount of underlying tokens to deposit
    /// @dev Second param (`recipient`) is ignored because it can only be the credit account
    function deposit(uint256 amount, address) external;

    /// @notice Withdraw the entire balance of underlying from the vault, disables yToken
    function withdraw() external;

    /// @notice Burn given amount of yTokens to withdraw corresponding amount of underlying from the vault
    /// @param maxShares Amout of yTokens to burn
    function withdraw(uint256 maxShares) external;

    /// @notice Burn given amount of yTokens to withdraw corresponding amount of underlying from the vault
    /// @param maxShares Amout of yTokens to burn
    /// @dev Second param (`recipient`) is ignored because it can only be the credit account
    function withdraw(uint256 maxShares, address) external;

    /// @notice Burn given amount of yTokens to withdraw corresponding amount of underlying from the vault
    /// @param maxShares Amout of yTokens to burn
    /// @param maxLoss Maximal slippage on withdrawal in basis points
    /// @dev Second param (`recipient`) is ignored because it can only be the credit account
    function withdraw(uint256 maxShares, address, uint256 maxLoss) external;
}