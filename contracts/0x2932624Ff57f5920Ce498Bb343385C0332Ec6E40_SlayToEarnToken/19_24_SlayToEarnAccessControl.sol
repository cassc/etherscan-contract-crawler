//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SlayToEarnAccessControl is AccessControl {

    bytes32 public constant INVENTORY_ADMIN_ROLE = bytes32(uint256(0x01));

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(INVENTORY_ADMIN_ROLE, msg.sender);

        _setRoleAdmin(INVENTORY_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function getDefaultAdminRole() public pure returns (bytes32) {
        return DEFAULT_ADMIN_ROLE;
    }

    function getInventoryAdminRole() public pure returns (bytes32) {
        return INVENTORY_ADMIN_ROLE;
    }
}