// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title YieldYak Strategy Interface
/// @notice Describes YieldYak Strategy methods
interface IYakStrategy {
    /// @notice Deposits specified amount to Yearn vault
    /// @param amount Amount to deposit
    function deposit(uint amount) external;

    /// @notice Withdraws amount from Yearn vault
    /// @param amount Amount to withdraw
    function withdraw(uint amount) external;

    /// @notice Returns amount of deposited tokens for shares
    /// @param amount Amount of shares
    /// @return deposit tokens for shares
    function getDepositTokensForShares(uint amount) external view returns (uint);

    /// @notice Returns number decimals of Strategy
    /// @return Number of decimals
    function decimals() external view returns (uint);

    /// @notice Deposit token
    /// @return Returns deposit token address
    function depositToken() external view returns (address);
}