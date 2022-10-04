// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IAccessControl, AccessControl, AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract AccessControlPermissible is Context, AccessControlEnumerable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant WL_OPERATOR_ROLE = keccak256("WL_OPERATOR_ROLE");

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function grantRole(bytes32 role, address account)
        public
        override(AccessControl, IAccessControl)
        onlyRole(ADMIN_ROLE)
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override(AccessControl, IAccessControl)
        onlyRole(ADMIN_ROLE)
    {
        _revokeRole(role, account);
    }
}