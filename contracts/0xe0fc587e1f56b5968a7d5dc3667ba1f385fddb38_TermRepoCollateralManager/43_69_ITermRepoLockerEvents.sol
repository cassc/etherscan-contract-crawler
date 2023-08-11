//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermRepoLockerEvents is an interface that defines all events emitted by the TermRepoLocker.
interface ITermRepoLockerEvents {
    /// @notice Event emitted when a TermRepoLocker is initialized.
    /// @param termRepoId term identifier
    /// @param termRepoLocker address of initialized term repo locker
    event TermRepoLockerInitialized(bytes32 termRepoId, address termRepoLocker);

    /// @notice Event emitted transfers for a TermRepoLocker are paused.
    /// @param termRepoId term identifier
    event TermRepoLockerTransfersPaused(bytes32 termRepoId);

    /// @notice Event emitted transfers for a TermRepoLocker are unpaused.
    /// @param termRepoId term identifier
    event TermRepoLockerTransfersUnpaused(bytes32 termRepoId);
}