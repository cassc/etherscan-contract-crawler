// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev DonatorBlacklist interface.
interface IDonatorBlacklist {
    /// @dev Gets account blacklisting status.
    /// @param account Account address.
    /// @return status Blacklisting status.
    function isDonatorBlacklisted(address account) external view returns (bool status);
}