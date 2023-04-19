// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

/**
 * @title IAggregatorVault
 * @author Spice Finance Inc
 */
interface IAggregatorVault {
    /// @notice Deposit weth into vault and receive receipt tokens
    /// @param vault Vault address
    /// @param assets The amount of weth being deposited
    /// @param minShares The minimum amount of shares to receive
    /// @return shares The amount of receipt tokens minted
    function deposit(
        address vault,
        uint256 assets,
        uint256 minShares
    ) external returns (uint256 shares);

    /// @notice Deposit weth into vault and receive receipt tokens
    /// @param vault Vault address
    /// @param shares The amount of receipt tokens to mint
    /// @param maxAssets The maximum amount of assets to deposit
    /// @return assets The amount of weth deposited
    function mint(
        address vault,
        uint256 shares,
        uint256 maxAssets
    ) external returns (uint256 assets);

    /// @notice Withdraw assets from vault
    /// @param vault Vault address
    /// @param assets The amount of weth being withdrawn
    /// @param maxShares The maximum amount of shares to burn
    /// @return shares The amount of shares burnt
    function withdraw(
        address vault,
        uint256 assets,
        uint256 maxShares
    ) external returns (uint256 shares);

    /// @notice Redeem assets from vault
    /// @param vault Vault address
    /// @param shares The amount of receipt tokens being burnt
    /// @param minAssets The minimum amount of assets to redeem
    /// @return assets The amount of assets redeemed
    function redeem(
        address vault,
        uint256 shares,
        uint256 minAssets
    ) external returns (uint256 assets);
}