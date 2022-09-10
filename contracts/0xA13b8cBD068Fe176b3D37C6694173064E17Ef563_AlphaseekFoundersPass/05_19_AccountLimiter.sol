// SPDX-License-Identifier: CC0
// Copyright (c) 2022 unReal Accelerator, LLC (https://unrealaccelerator.io)
pragma solidity ^0.8.9;

/**
 * @title AccountLimiter
 * @author [email protected]
 * @notice A utility contract that provides functions for:
 * - Enforcing a default account limit for all accounts || account limit for specific accounts
 * - Providing the limit for a specific account
 * - Providing a count for a specific account
 * - Providing validation that a account transaction will not exceed it's limit
 * - Note on Limitations:
 * --- Does not allow for infinite limits
 * --- Does not allow for multiple transaction types. In other words, you can keep up with
 * --- the number of mints or claims but not mints and claims independently.
 */

contract AccountLimiter {
    /**
    @dev A mapping to keep up with a accounts transaction count
    @notice Contracts implementing this utility need to call _incrementAccountCount()
    */
    mapping(address => uint256) private accountCount;
    /**
    @dev A mapping to keep up with specific accounts transaction limits
    @notice Contracts implementing this utility need to call _incrementAccountCount()
    */
    mapping(address => uint256) private accountLimit;
    /**
    @dev A default limit for all accounts without a specified limit
    @notice Contracts implementing this utility need to call _setAccountLimitDefault
    to update the limit from the default of 0
    */
    uint256 private accountLimitDefault;

    function _setAccountLimitDefault(uint256 accountMintLimitDefault_)
        internal
    {
        accountLimitDefault = accountMintLimitDefault_;
    }

    function _setAccountLimit(address account, uint256 accountMintLimit_)
        internal
    {
        accountLimit[account] = accountMintLimit_;
    }

    /**
    @dev Gets the account limit
    @notice Contracts implementing this contract can call this function to
    get the current account limit
    @param account The account for which the current count is being requested
    */
    function _getAccountLimit(address account) internal view returns (uint256) {
        return
            (accountLimit[account] > 0)
                ? accountLimit[account]
                : accountLimitDefault;
    }

    /**
    @dev Increments the account count
    @notice Contracts implementing this contract should call this function from
    transactions which are being limited for a specific account
    @param account The account for which the transaction is occuring
    @param amount The quantity of the thing that is being limited
    */
    function _incrementAccountCount(address account, uint256 amount) internal {
        unchecked {
            accountCount[account] += amount;
        }
    }

    /**
    @dev Gets the account count
    @notice Contracts implementing this contract can call this function to
    get the current account count
    @param account The account for which the current count is being requested
    */
    function _getAccountCount(address account) internal view returns (uint256) {
        return accountCount[account];
    }

    /**
    @dev Returns a boolean indicating whether the requested transaction should occur
    based on the account's limit
    @notice Returns true if the transaction does not violate the limit for the
    specified account. Returns false if the transaction will violate the limit for
    the specified account
    @param account The account for which the transaction is being verified
    @param amount The quantity of the thing that is being limited
    */
    function _validateAccountCount(address account, uint256 amount)
        internal
        view
        returns (bool)
    {
        return ((accountCount[account] + amount) <=
            (
                (accountLimit[account] > 0)
                    ? accountLimit[account]
                    : accountLimitDefault
            ));
    }
}