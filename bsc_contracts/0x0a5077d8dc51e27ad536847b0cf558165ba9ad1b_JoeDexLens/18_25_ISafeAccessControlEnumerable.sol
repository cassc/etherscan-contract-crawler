// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ISafeOwnable.sol";

interface ISafeAccessControlEnumerable is ISafeOwnable {
    error SafeAccessControlEnumerable__OnlyRole(address account, bytes32 role);
    error SafeAccessControlEnumerable__OnlyOwnerOrRole(address account, bytes32 role);
    error SafeAccessControlEnumerable__RoleAlreadyGranted(address account, bytes32 role);
    error SafeAccessControlEnumerable__AccountAlreadyHasRole(address account, bytes32 role);
    error SafeAccessControlEnumerable__AccountDoesNotHaveRole(address account, bytes32 role);

    event RoleGranted(address indexed sender, bytes32 indexed role, address indexed account);
    event RoleRevoked(address indexed sender, bytes32 indexed role, address indexed account);
    event RoleAdminSet(address indexed sender, bytes32 indexed role, bytes32 indexed adminRole);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getRoleMemberAt(bytes32 role, uint256 index) external view returns (address);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role) external;
}