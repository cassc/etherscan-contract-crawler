//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice TermRepoLocker contracts lock collateral and purchase tokens
/// @notice Methods should only be callable from paired TermManager.
interface ITermRepoLocker {
    /// @notice Locks tokens from origin wallet
    /// @notice Reverts if caller doesn't have SERVICER_ROLE
    /// @param originWallet Origin wallet to transfer tokens from
    /// @param token Address of token being transferred
    /// @param amount Amount of tokens to transfer
    function transferTokenFromWallet(
        address originWallet,
        address token,
        uint256 amount
    ) external;

    /// @notice Unlocks tokens to destination wallet
    /// @dev Reverts if caller doesn't have SERVICER_ROLE
    /// @param destinationWallet Destination wallet to unlock tokens to
    /// @param token Address of token being unlocked
    /// @param amount Amount of tokens to unlock
    function transferTokenToWallet(
        address destinationWallet,
        address token,
        uint256 amount
    ) external;
}