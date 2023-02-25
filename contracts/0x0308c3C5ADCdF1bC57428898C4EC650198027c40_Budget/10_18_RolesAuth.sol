// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AddressUint8FlagsLib} from "./utils/AddressUint8FlagsLib.sol";

import {IRoles} from "../roles/interfaces/IRoles.sol";

uint8 constant ROLES_FLAG_TYPE = 0x01;

abstract contract RolesAuth {
    using AddressUint8FlagsLib for address;

    // ROLES_SLOT = keccak256("firm.rolesauth.roles") - 1
    bytes32 internal constant ROLES_SLOT = 0x7aaf26e54f46558e57a4624b01631a5da30fe5fe9ba2f2500c3aee185f8fb90b;

    function roles() public view returns (IRoles rolesAddr) {
        assembly {
            rolesAddr := sload(ROLES_SLOT)
        }
    }

    function _setRoles(IRoles roles_) internal {
        assembly {
            sstore(ROLES_SLOT, roles_)
        }
    }

    error UnexistentRole(uint8 roleId);

    function _validateAuthorizedAddress(address authorizedAddr) internal view {
        if (authorizedAddr.isFlag(ROLES_FLAG_TYPE)) {
            uint8 roleId = authorizedAddr.flagValue();
            if (!roles().roleExists(roleId)) {
                revert UnexistentRole(roleId);
            }
        }
    }

    function _isAuthorized(address actor, address authorizedAddr) internal view returns (bool) {
        if (authorizedAddr.isFlag(ROLES_FLAG_TYPE)) {
            return roles().hasRole(actor, authorizedAddr.flagValue());
        } else {
            return actor == authorizedAddr;
        }
    }
}