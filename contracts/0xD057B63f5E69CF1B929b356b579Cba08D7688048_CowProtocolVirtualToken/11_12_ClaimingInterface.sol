// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.10;

/// @dev The contract functions that are shared between the `Claiming` and
/// `MerkleDistributor` contracts. The two components are handled and tested
/// separately and are linked to each other by the functions in this contract.
/// This contracs is for all intents and purposes an interface, however actual
/// interfaces cannot declare internal functions.
/// @title COW token claiming interface.
/// @author CoW Protocol Developers
abstract contract ClaimingInterface {
    /// @dev Exhaustive list of the different branches of the claiming logic.
    enum ClaimType {
        Airdrop,
        GnoOption,
        UserOption,
        Investor,
        Team,
        Advisor
    }

    /// @dev This function is executed when a valid proof of the claim is
    /// provided and executes all steps required for each claim type.
    /// @param claimType Which claim will be performed. See [`ClaimType`] for
    /// an exausting list.
    /// @param payer The address that will pay if the claim to be performed
    /// requires a payment.
    /// @param claimant The account to which the claim is assigned and which
    /// will receive the corresponding virtual tokens.
    /// @param claimedAmount The amount that the user decided to claim (after
    /// vesting if it applies).
    /// @param sentNativeTokens The amount of native tokens that the user sent
    /// along with the transaction.
    function performClaim(
        ClaimType claimType,
        address payer,
        address claimant,
        uint256 claimedAmount,
        uint256 sentNativeTokens
    ) internal virtual;
}