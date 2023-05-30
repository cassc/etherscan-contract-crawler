/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title IBatcher
 * @notice A batcher to resolve vault deposits/withdrawals in batches
 * @dev Provides an interface for Batcher
 */
interface IBatcher {
    /// @notice Data structure to store vault info
    /// @param vaultAddress Address of the vault
    /// @param tokenAddress Address vault's want token
    /// @param maxAmount Max amount of tokens to deposit in vault
    /// @param currentAmount Current amount of wantTokens deposited in the vault
    struct VaultInfo {
        address vaultAddress;
        address tokenAddress;
    }

    /// @notice Withdraw initiate event
    /// @param sender Address of the withdawer
    /// @param vault Address of the vault
    /// @param amountOut Tokens deposited
    event WithdrawRequest(
        address indexed sender,
        address indexed vault,
        uint256 amountOut
    );

    /// @notice Withdraw rescinded/cancelled event
    /// @param sender Address of the withdawer
    /// @param vault Address of the vault
    /// @param amountCancelled Amount requested to be cancelled
    event WithdrawRescinded(
        address indexed sender,
        address indexed vault,
        uint256 amountCancelled
    );

    /// @notice Batch Withdraw event
    /// @param amountOut Tokens withdrawn
    /// @param totalUsers Total number of users in the batch
    event BatchWithdrawSuccessful(uint256 amountOut, uint256 totalUsers);

    /// @notice Withdraw complete event
    /// @param sender Address of the withdawer
    /// @param vault Address of the vault
    /// @param amountOut Tokens deposited
    event WithdrawComplete(
        address indexed sender,
        address indexed vault,
        uint256 amountOut
    );

    // function claimTokens(uint256 amount, address recipient) external;

    function initiateWithdrawal(uint256 amountIn) external;

    function cancelWithdrawal(uint256 amountIn) external;

    function completeWithdrawal(uint256 amountOut, address recipient) external;

    function batchWithdraw(address[] memory users) external;

    function completeWithdrawalWithZap(uint256 amountOut, address recipient)
        external;

    // function setVaultLimit(uint256 maxLimit) external;
}