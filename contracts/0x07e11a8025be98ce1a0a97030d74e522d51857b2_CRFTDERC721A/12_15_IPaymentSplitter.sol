// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPaymentSplitter {
    /**
     * @dev Emitted when an account has successfully withdrawn tokens.
     *
     * @param account   The address of the account that withdrew the tokens.
     * @param value     The amount of tokens that were withdrawn.
     */
    event Withdrawn(address account, uint256 value);

    /**
     * @dev When the share total is not equivalent to `95`.
     */
    error InvalidShare();

    /**
     * @dev When given address is zero.
     */
    error ZeroAddress();

    /**
     * @dev When given share is zero.
     */
    error ZeroShare();

    /**
     * @dev When contract try to reentrant calls to a function.
     */
    error Reentrancy();

    struct Payees {
        // A address of account
        address account;
        // A share of the account
        uint96 share;
    }
}