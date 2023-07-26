//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @notice ITermRepoTokenEvents is an interface that defines all events emitted by the Term Repo Token
interface ITermRepoTokenEvents {
    /// @notice Event emitted when a Term Repo Servicer is initialized.
    /// @param termRepoId term identifier
    /// @param termRepoToken   address of initialized term repo token
    /// @param redemptionRatio The number of purchase tokens redeemable per unit of Term Repo Token at par
    event TermRepoTokenInitialized(
        bytes32 termRepoId,
        address termRepoToken,
        uint256 redemptionRatio
    );

    /// @notice Event emitted when a Term Repo Token Minting is Paused
    /// @param termRepoId A Term Repo id
    event TermRepoTokenMintingPaused(bytes32 termRepoId);

    /// @notice Event emitted when a Term Repo Token Minting is Unpaused
    /// @param termRepoId A Term Repo id
    event TermRepoTokenMintingUnpaused(bytes32 termRepoId);

    /// @notice Event emitted when a Term Repo Token Burning is Paused
    /// @param termRepoId A Term Repo id
    event TermRepoTokenBurningPaused(bytes32 termRepoId);

    /// @notice Event emitted when a Term Repo Token Burning is Unpaused
    /// @param termRepoId A Term Repo id
    event TermRepoTokenBurningUnpaused(bytes32 termRepoId);
}