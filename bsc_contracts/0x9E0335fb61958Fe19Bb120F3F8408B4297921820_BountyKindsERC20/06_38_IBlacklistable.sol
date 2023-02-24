// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBlacklistable {
    event UserStatusSet(
        address indexed operator,
        address indexed account,
        bool indexed isBlacklisted
    );

    /**
     * @dev Set the status of an account to either blacklisted or not blacklisted.
     * @param account_ The address to change the status of.
     * @param status The new status for the address. True for blacklisted, false for not blacklisted.
     */
    function setUserStatus(address account_, bool status) external;

    /**
     * @dev Check if an address is blacklisted.
     * @param account_ The address to check.
     * @return True if the address is blacklisted, false otherwise.
     */
    function isBlacklisted(address account_) external view returns (bool);

    function areBlacklisted(
        address[] calldata accounts_
    ) external view returns (bool);
}