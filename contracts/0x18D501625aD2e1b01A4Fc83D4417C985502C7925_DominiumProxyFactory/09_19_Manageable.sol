//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ExtendedAccessControl} from "./ExtendedAccessControl.sol";

/// @author Amit Molek
/// @dev Role-based managment based on OpenZeppelin's AccessControl.
/// This contract gives 2 roles: the `admin` and `managers`. Both of them
/// can access restricted functions but only the `admin` can add/remove `managers`
/// and create new roles.
contract Manageable is ExtendedAccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor(address admin, address[] memory managers) {
        require(admin != address(0), "Manageable: admin address zero");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, managers);
    }

    modifier onlyAuthorized() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(MANAGER_ROLE, msg.sender),
            "Manageable: Unauthorized access"
        );
        _;
    }
}