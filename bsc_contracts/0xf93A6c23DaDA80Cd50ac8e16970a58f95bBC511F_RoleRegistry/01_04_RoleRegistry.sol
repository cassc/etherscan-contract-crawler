// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

import "EnumerableSet.sol";
import "RoleLibrary.sol";
import "IRoleRegistry.sol";

contract RoleRegistry is IRoleRegistry {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Role {
        mapping(address => bool) members;
        bytes32 adminRole;
        EnumerableSet.AddressSet roleMembers;
    }

    mapping(bytes32 => Role) private roles;

    modifier onlyAdmin() {
        require(hasRole(Roles.ADMIN, msg.sender), "Unauthorized Access!");
        _;
    }

    constructor(address _admin, address _adminBackup) {
        _grantRole(Roles.ADMIN, _admin);
        _grantRole(Roles.ADMIN, _adminBackup);
    }

    function grantRole(bytes32 _role, address account)
        external
        override
        onlyAdmin
    {
        require(_role != Roles.ADMIN, "Cannot grant admin role");
        _grantRole(_role, account);
    }

    function revokeRole(bytes32 _role, address account)
        external
        override
        onlyAdmin
    {
        require(hasRole(_role, account), "Account does not have the role");
        require(_role != Roles.ADMIN, "Cannot revoke admin role");
        _revokeRole(_role, account);
    }

    function hasRole(bytes32 _role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return roles[_role].members[account];
    }

    function _grantRole(bytes32 _role, address account) internal {
        roles[_role].members[account] = true;
        roles[_role].roleMembers.add(account);
    }

    function _revokeRole(bytes32 _role, address account) internal {
        delete roles[_role].members[account];
        roles[_role].roleMembers.remove(account);
    }
}