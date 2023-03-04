// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import "EnumerableSet.sol";

import "ISimpleAccessControl.sol";

contract SimpleAccessControl is ISimpleAccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) internal roles;

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "not authorized");
        _;
    }

    function _grantRole(bytes32 role, address account) internal {
        roles[role].add(account);
    }

    function _revokeRole(bytes32 role, address account) internal {
        roles[role].remove(account);
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return roles[role].contains(account);
    }

    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return roles[role].length();
    }

    function accountsWithRole(bytes32 role) external view override returns (address[] memory) {
        return roles[role].values();
    }
}