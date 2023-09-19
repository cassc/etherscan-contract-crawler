// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ErrorsAndEvents {
    /**
     * @dev Revert with an error when the caller has insufficient balance.
     */
    error InsufficientBalance();

    /**
     * @dev Revert with an error when the caller is not the creator of the token id.
     */
    error InvalidTokenOwner();

    /**
     * @dev Revert with an error when the caller is not an approved caller.
     */
    error UnapprovedCaller();

    /**
     * @dev Revert with an error when the quantity is not greater than zero.
     */
    error InvalidQuantity();

    /**
     * @dev Revert with an error when the quantity exceeds the supply.
     */
    error ExceedsSupply();

    /**
     * @dev Revert with an error when the array lengths do not match.
     */
    error ArrayLengthMismatch();

    /**
     * @dev An event with the updated base uri.
     */
    event BaseUriChanged(string uri);
}