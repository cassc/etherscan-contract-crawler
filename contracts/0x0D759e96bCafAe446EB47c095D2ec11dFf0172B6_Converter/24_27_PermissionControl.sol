// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @dev ASM Genome Mining - PermissionControl contract
 */

bytes32 constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
bytes32 constant MULTISIG_ROLE = keccak256("MULTISIG_ROLE");
bytes32 constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
bytes32 constant DAO_ROLE = keccak256("DAO_ROLE");
bytes32 constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");

string constant MISSING_ROLE = "Missing required role";

contract PermissionControl is AccessControlEnumerable {
    error AccessDenied(string errMsg);

    /**
     * @dev Modifier that checks that an account has at least one role in `roles`.
     * Reverts with a standardized message.
     */
    modifier eitherRole(bytes32[2] memory roles) {
        if (!hasRole(roles[0], _msgSender()) && !hasRole(roles[1], _msgSender())) {
            revert AccessDenied(MISSING_ROLE);
        }
        _;
    }

    /**
     * @dev Revoke all members to `role`
     * @dev Internal function without access restriction.
     */
    function _clearRole(bytes32 role) internal {
        uint256 count = getRoleMemberCount(role);
        for (uint256 i = count; i > 0; i--) {
            _revokeRole(role, getRoleMember(role, i - 1));
        }
    }

    /**
     * @dev Grant CONSUMER_ROLE to `addr`.
     * @dev Can only be called from Controller or Multisig
     */
    function addConsumer(address addr) public eitherRole([CONTROLLER_ROLE, MULTISIG_ROLE]) {
        _grantRole(CONSUMER_ROLE, addr);
    }

    /**
     * @dev Revoke CONSUMER_ROLE to `addr`.
     * @dev Can only be called from Controller or Multisig
     */
    function removeConsumer(address addr) public eitherRole([CONTROLLER_ROLE, MULTISIG_ROLE]) {
        _revokeRole(CONSUMER_ROLE, addr);
    }

    /**
     * @dev Grant MANAGER_ROLE to `addr`.
     * @dev Can only be called from Controller or Multisig
     */
    function addManager(address addr) public eitherRole([CONTROLLER_ROLE, MULTISIG_ROLE]) {
        _grantRole(MANAGER_ROLE, addr);
    }

    /**
     * @dev Revoke MANAGER_ROLE to `addr`.
     * @dev Can only be called from Controller or Multisig
     */
    function removeManager(address addr) public eitherRole([CONTROLLER_ROLE, MULTISIG_ROLE]) {
        _revokeRole(MANAGER_ROLE, addr);
    }
}