//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Owner managment using multi-sig
/// @author Amit Molek
interface IMultisigOwnerCut {
    enum OwnerCutAction {
        ADD,
        REPLACE,
        REMOVE
    }

    struct OwnerCut {
        OwnerCutAction action;
        /// @dev ADD: The account you want to add as an owner
        /// REPLACE: The account you want to replace the old owner with
        /// REMOVE: The account you want to remove
        address account;
        /// @dev Used in REPLACE mode. This is the account you want to replace
        address prevAccount;
        /// @dev Cut's deadline
        uint256 endsAt;
    }

    /// @dev Emitted on `ownerCut`
    /// @param cut The cut that was executed
    event OwnerCutExecuted(OwnerCut cut);

    /// @dev Indicates that an invalid owner cut action happend
    error InvalidOwnerCutAction(uint256 action);

    /// @notice Add/Replace/Remove owners
    /// @dev Explain to a developer any extra details
    /// @param cut Contains the action to execute
    /// @param signatures A set of approving EIP712 signatures on `cut`
    function ownerCut(OwnerCut memory cut, bytes[] memory signatures) external;
}