// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @title Interface for the Darwin Presale
interface IDarwinPresale {

    /// Presale contract is already initialized
    error AlreadyInitialized();
    /// Presale contract is not initialized
    error NotInitialized();
    /// Presale has not started yet
    error PresaleNotActive();
    /// Presale has not ended yet
    error PresaleNotEnded();
    /// Parameter cannot be the zero address
    error ZeroAddress();
    /// Start date cannot be less than the current timestamp
    error InvalidStartDate();
    /// End date cannot be less than the start date or the current timestamp
    error InvalidEndDate();
    /// Deposit amount must be between 0.1 and 4,000 BNB
    error InvalidDepositAmount();
    /// Deposit amount exceeds the hardcap
    error AmountExceedsHardcap();
    /// Attempted transfer failed
    error TransferFailed();
    /// ERC20 token approval failed
    error ApproveFailed();

    /// @notice Emitted when bnb is deposited
    /// @param user Address of the user who deposited
    /// @param amountIn Amount of BNB deposited
    /// @param darwinAmount Amount of Darwin received
    event UserDeposit(address indexed user, uint256 indexed amountIn, uint256 indexed darwinAmount);
    event PresaleEndDateSet(uint256 indexed endDate);
    event Wallet1Set(address indexed wallet1);
    event Wallet2Set(address indexed wallet2);
    event RouterSet(address indexed router);
    event LpProvided(uint256 indexed lpAmount, uint256 indexed remainingAmount);
    
}