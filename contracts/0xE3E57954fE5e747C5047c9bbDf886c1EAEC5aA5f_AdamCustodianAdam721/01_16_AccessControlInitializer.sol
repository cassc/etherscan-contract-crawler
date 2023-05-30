// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";


abstract contract AccessControlInitializer is AccessControl {
    function _setupRoleBatch(bytes32[] memory roles, address[] memory addresses) internal virtual {
        require(roles.length == addresses.length, "AccessControlInitializer: roles and addresses length mismatch");
        for (uint i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "AccessControlInitializer: grant to the zero address");
            _setupRole(roles[i], addresses[i]);
        }
    }
}