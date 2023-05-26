// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract APEXAccessControl is AccessControl {
    bytes32 constant ADMINISTRATOR = keccak256("ADMINISTRATOR");
    bytes32 constant BUSINESS_MANAGER = keccak256("BUSINESS_MANAGER");
    bytes32 constant MEMBERSHIP_CONTRACT = keccak256("MEMBERSHIP_CONTRACT");

    constructor() {
        _grantRole(ADMINISTRATOR, msg.sender);
        _setRoleAdmin(ADMINISTRATOR, ADMINISTRATOR);
        _setRoleAdmin(BUSINESS_MANAGER, ADMINISTRATOR);
        _setRoleAdmin(MEMBERSHIP_CONTRACT, ADMINISTRATOR);
    }
}