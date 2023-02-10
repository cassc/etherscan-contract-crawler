// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract FrankenDAOErrors {
    // General purpose
    error NotAuthorized();

    // Staking
    error NonExistentToken();
    error InvalidDelegation();
    error Paused();
    error InvalidParameter();
    error TokenLocked();
    error StakedTokensCannotBeTransferred();

    // Governance
    error ZeroAddress();
    error AlreadyInitialized();
    error ParameterOutOfBounds();
    error InvalidId();
    error InvalidProposal();
    error InvalidStatus();
    error InvalidInput();
    error AlreadyVoted();
    error NotEligible();
    error NotInActiveProposals();
    error NotStakingContract();

    // Executor
    error DelayNotSatisfied();
    error IdenticalTransactionAlreadyQueued();
    error TransactionNotQueued();
    error TimelockNotMet();
    error TransactionReverted();
}