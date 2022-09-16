// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title yToken interface
/// @notice Describes Yearn token methods
interface IYearnVault {
    /// @notice Deposits specified amount to Yearn vault
    /// @param amount Amount to deposit
    function deposit(uint amount) external;

    /// @notice Withdraws amount from Yearn vault
    /// @param amount Amount to withdraw
    function withdraw(uint amount) external;

    /// @notice Returns price per single share
    /// @return Price per share
    function pricePerShare() external view returns (uint);

    /// @notice Returns number decimals of Vault
    /// @return Number of decimals
    function decimals() external view returns (uint);

    /// @notice yToken address
    /// @return Returns yToken address
    function token() external view returns (address);
}