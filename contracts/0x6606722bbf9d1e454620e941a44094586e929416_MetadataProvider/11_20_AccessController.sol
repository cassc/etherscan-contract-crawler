// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import "./Errors.sol";

contract AccessController is AccessControlEnumerable {
    bytes32 public constant ADMIN_ROLE = bytes32(0x00); // Redeclares DEFAULT_ADMIN_ROLE
    bytes32 public constant ADDRESS_MANAGER_ROLE = keccak256("ADDRESS_MANAGER_ROLE");
    bytes32 public constant ONBOARDING_MANAGER_ROLE = keccak256("ONBOARDING_MANAGER_ROLE");
    bytes32 public constant PAYMENT_MANAGER_ROLE = keccak256("PAYMENT_MANAGER_ROLE");
    bytes32 public constant REPLICAN_MANAGER_ROLE = keccak256("REPLICAN_MANAGER_ROLE");
    bytes32 public constant METADATA_MANAGER_ROLE = keccak256("METADATA_MANAGER_ROLE");

    constructor(address admin) {
        if (admin == address(0)) revert Errors.NullAddressNotAllowed();

        _grantRole(ADMIN_ROLE, admin);
    }

    function checkRole(bytes32 role, address caller) public view {
        if (hasRole(ADMIN_ROLE, caller)) return;

        _checkRole(role, caller);
    }

}