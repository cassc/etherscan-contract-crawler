// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IACLExceptions {
    /// @dev Thrown when attempting to delete an address from a set that is not a pausable admin
    error AddressNotPausableAdminException(address addr);

    /// @dev Thrown when attempting to delete an address from a set that is not a unpausable admin
    error AddressNotUnpausableAdminException(address addr);
}

interface IACLEvents {
    /// @dev Emits when a new admin is added that can pause contracts
    event PausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when a Pausable admin is removed
    event PausableAdminRemoved(address indexed admin);

    /// @dev Emits when a new admin is added that can unpause contracts
    event UnpausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when an Unpausable admin is removed
    event UnpausableAdminRemoved(address indexed admin);
}

/// @title ACL interface
interface IACL is IACLEvents, IACLExceptions, IVersion {
    /// @dev Returns true if the address is a pausable admin and false if not
    /// @param addr Address to check
    function isPausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if the address is unpausable admin and false if not
    /// @param addr Address to check
    function isUnpausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if an address has configurator rights
    /// @param account Address to check
    function isConfigurator(address account) external view returns (bool);

    /// @dev Returns address of configurator
    function owner() external view returns (address);
}