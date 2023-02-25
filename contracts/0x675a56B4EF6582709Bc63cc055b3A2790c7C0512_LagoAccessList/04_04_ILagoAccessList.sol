// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

address constant LAGO_ACCESS_ANY = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

/// @dev Interface definition for LagoAccessList
interface ILagoAccessList {
    /// set `addr`->`LAGO_ACCESS_ANY` to `status`
    /// @param addr the address
    /// @param status true to include on list, false to remove
    function set(address addr, bool status) external;

    /// set `addr1`->`addr2` to `status`
    /// @param addr1 the first address
    /// @param addr2 the second address
    /// @param status true to include on list, false to remove
    function set(address addr1, address addr2, bool status) external;

    /// check if the `addr1`->`addr2` pair is a member of the list
    /// @param addr1 address to check
    /// @param addr2 address to check
    /// @return true if `addr` is a member of the list, false otherwise
    function isMember(address addr1, address addr2) external view returns (bool);
}