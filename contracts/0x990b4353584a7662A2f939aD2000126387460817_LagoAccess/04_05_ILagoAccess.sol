// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// @dev Interface definition for LagoAccessList
interface ILagoAccess {
    /// @dev check if the address is permitted per the allow & deny lists
    /// @param a address to check
    /// @return allowed true if permitted, false if not
    function isAllowed(address a) external view returns (bool allowed);

    /// @dev check if the address pair is permitted per the allow & deny lists
    /// @param a first address to check
    /// @param b second address to check
    /// @return allowed true if permitted, false if not
    function isAllowed(address a, address b) external view returns (bool allowed);
}