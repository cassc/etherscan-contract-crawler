// SPDX-License-Identifier: UNLICENSED
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
        uint256 maxAmount;
    }

    /// @notice PermitParams to provide permit for want token deposit approval
    /// @param value Amount of want tokens to approve
    /// @param deadline unix timestamp of permit validity
    /// @param v signarure param
    /// @param r signarure param
    /// @param s signarure param
    struct PermitParams {
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    /// @notice Deposit event
    /// @param sender Address of the depositor
    /// @param vault Address of the vault
    /// @param amountIn Tokens deposited
    event DepositRequest(
        address indexed sender,
        address indexed vault,
        uint256 amountIn
    );

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

    /// @notice Batch Deposit event
    /// @param amountIn Tokens deposited
    /// @param totalUsers Total number of users in the batch
    event BatchDepositSuccessful(uint256 amountIn, uint256 totalUsers);

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

    /// @notice Verification authority update event
    /// @param oldVerificationAuthority address of old verification authority
    /// @param newVerificationAuthority address of new verification authority
    event VerificationAuthorityUpdated(
        address indexed oldVerificationAuthority,
        address indexed newVerificationAuthority
    );

    /// @notice Vault limit update event
    /// @param vaultAddress address of vault
    /// @param oldMaxAmount old vault max deposit limit
    /// @param newMaxAmount new vault max deposit limit
    event VaultLimitUpdated(
        address indexed vaultAddress,
        uint256 oldMaxAmount,
        uint256 newMaxAmount
    );

    function depositFunds(
        uint256 amountIn,
        bytes memory signature,
        address recipient,
        PermitParams memory params
    ) external;

    function claimTokens(uint256 amount, address recipient) external;

    function initiateWithdrawal(uint256 amountIn) external;

    function cancelWithdrawal(uint256 amountIn) external;

    function completeWithdrawal(uint256 amountOut, address recipient) external;

    function batchDeposit(address[] memory users) external;

    function batchWithdraw(address[] memory users) external;

    function setVaultLimit(uint256 maxLimit) external;
}