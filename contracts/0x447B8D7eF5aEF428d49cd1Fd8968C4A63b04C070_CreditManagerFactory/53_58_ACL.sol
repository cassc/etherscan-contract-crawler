// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Claimable } from "./access/Claimable.sol";
import { IACL } from "../interfaces/IACL.sol";

/// @title ACL contract that stores admin addresses
/// More info: https://dev.gearbox.fi/security/roles
contract ACL is IACL, Claimable {
    mapping(address => bool) public pausableAdminSet;
    mapping(address => bool) public unpausableAdminSet;

    // Contract version
    uint256 public constant version = 1;

    /// @dev Adds an address to the set of admins that can pause contracts
    /// @param newAdmin Address of a new pausable admin
    function addPausableAdmin(address newAdmin)
        external
        onlyOwner // T:[ACL-1]
    {
        pausableAdminSet[newAdmin] = true; // T:[ACL-2]
        emit PausableAdminAdded(newAdmin); // T:[ACL-2]
    }

    /// @dev Removes an address from the set of admins that can pause contracts
    /// @param admin Address of admin to be removed
    function removePausableAdmin(address admin)
        external
        onlyOwner // T:[ACL-1]
    {
        if (!pausableAdminSet[admin]) {
            revert AddressNotPausableAdminException(admin);
        }
        pausableAdminSet[admin] = false; // T:[ACL-3]
        emit PausableAdminRemoved(admin); // T:[ACL-3]
    }

    /// @dev Returns true if the address is a pausable admin and false if not
    /// @param addr Address to check
    function isPausableAdmin(address addr)
        external
        view
        override
        returns (bool)
    {
        return pausableAdminSet[addr]; // T:[ACL-2,3]
    }

    /// @dev Adds unpausable admin address to the list
    /// @param newAdmin Address of new unpausable admin
    function addUnpausableAdmin(address newAdmin)
        external
        onlyOwner // T:[ACL-1]
    {
        unpausableAdminSet[newAdmin] = true; // T:[ACL-4]
        emit UnpausableAdminAdded(newAdmin); // T:[ACL-4]
    }

    /// @dev Adds an address to the set of admins that can unpause contracts
    /// @param admin Address of admin to be removed
    function removeUnpausableAdmin(address admin)
        external
        onlyOwner // T:[ACL-1]
    {
        if (!unpausableAdminSet[admin]) {
            revert AddressNotUnpausableAdminException(admin);
        }
        unpausableAdminSet[admin] = false; // T:[ACL-5]
        emit UnpausableAdminRemoved(admin); // T:[ACL-5]
    }

    /// @dev Returns true if the address is unpausable admin and false if not
    /// @param addr Address to check
    function isUnpausableAdmin(address addr)
        external
        view
        override
        returns (bool)
    {
        return unpausableAdminSet[addr]; // T:[ACL-4,5]
    }

    /// @dev Returns true if an address has configurator rights
    /// @param account Address to check
    function isConfigurator(address account)
        external
        view
        override
        returns (bool)
    {
        return account == owner(); // T:[ACL-6]
    }

    function owner() public view override(IACL, Ownable) returns (address) {
        return Ownable.owner();
    }
}