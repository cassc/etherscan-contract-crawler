// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.10;

/// @dev The contract functions that are shared between the `Vesting` and
/// `Claiming` contracts. The two components are handled and tested
/// separately and are linked to each other by the functions in this contract.
/// This contracs is for all intents and purposes an interface, however actual
/// interfaces cannot declare internal functions.
/// @title COW token vesting interface.
/// @author CoW Protocol Developers
abstract contract VestingInterface {
    /// @dev Adds an amount that will be vested over time.
    /// Should be called from the parent contract on redeeming a vested claim.
    /// @param user The user for whom the vesting is performed.
    /// @param vestingAmount The (added) amount to be vested in time.
    /// @param isCancelableFlag Flag whether the vesting is cancelable
    function addVesting(
        address user,
        uint256 vestingAmount,
        bool isCancelableFlag
    ) internal virtual;

    /// @dev Computes the current vesting from the total vested amount and marks
    /// that amount as converted. This is called by the parent contract every
    /// time virtual tokens from a vested claim are swapped into real tokens.
    /// @param user The user for which the amount is vested.
    /// @return Amount converted.
    function vest(address user) internal virtual returns (uint256);

    /// @dev Transfers a cancelable vesting of a user to another address.
    /// Returns the amount of token that is not yet converted.
    /// @param user The user for whom the vesting is removed.
    /// @param freedVestingBeneficiary The address to which to assign the amount
    /// that remains to be vested.
    /// @return accruedVesting The total number of tokens that remain to be
    /// converted
    function shiftVesting(address user, address freedVestingBeneficiary)
        internal
        virtual
        returns (uint256 accruedVesting);
}