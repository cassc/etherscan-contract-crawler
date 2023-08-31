//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/// @notice ITermRepoCollateralManagerEvents is an interface that defines all events emitted by Term Repo Collateral Manager.
interface ITermRepoRolloverManagerEvents {
    /// @notice Event emitted when a rollover manager is initialized
    /// @param termRepoId A Term Repo id
    /// @param rolloverManager Address of rollover manager
    event TermRepoRolloverManagerInitialized(
        bytes32 termRepoId,
        address rolloverManager
    );

    /// @notice Event emitted when a rollover manager approves a future term as a destination for borrows
    /// @param termRepoId A Term Repo id
    /// @param rolloverTermAuctionId The Term Auction Id that rollover bid will be submitted into
    event RolloverTermApproved(
        bytes32 termRepoId,
        bytes32 rolloverTermAuctionId
    );

    /// @notice Event emitted when a rollover manager revokes approval for a future term as a destination for borrows
    /// @param termRepoId A Term Repo id
    /// @param rolloverTermAuctionId The Term Auction Id that rollover bid will be submitted into
    event RolloverTermApprovalRevoked(
        bytes32 termRepoId,
        bytes32 rolloverTermAuctionId
    );

    /// @notice Event emitted when a borrower elects a rollover contract
    /// @param termRepoId A Term Repo id
    /// @param rolloverTermRepoId Term Repo Id of Rollover Term Repo
    /// @param borrower The address of the borrower
    /// @param rolloverAuction The address of rollover term contract
    /// @param rolloverAmount Amount of purchase currency borrower is rolling over
    /// @param hashedBidPrice The hash of rollover bid price
    event RolloverElection(
        bytes32 termRepoId,
        bytes32 rolloverTermRepoId,
        address borrower,
        address rolloverAuction,
        uint256 rolloverAmount,
        bytes32 hashedBidPrice
    );

    /// @notice Event emitted when a borrower cancels a rollover election
    /// @param termRepoId A Term Repo id
    /// @param borrower The address of the borrower
    event RolloverCancellation(bytes32 termRepoId, address borrower);

    /// @notice Event emitted when a bid is locked for a borrower rollover
    /// @param termRepoId A Term Repo id
    /// @param borrower The address of borrower
    event RolloverBidLockSucceeded(bytes32 termRepoId, address borrower);

    /// @notice Event emitted when a bid fails to be locked for a borrower rollover
    /// @param termRepoId A Term Repo id
    /// @param borrower The address of borrower
    event RolloverBidLockFailed(bytes32 termRepoId, address borrower);

    /// @notice Event emitted when a rollover is processed completely
    /// @param termRepoId A Term Repo id
    /// @param borrower The address of borrower
    event RolloverProcessed(bytes32 termRepoId, address borrower);
}