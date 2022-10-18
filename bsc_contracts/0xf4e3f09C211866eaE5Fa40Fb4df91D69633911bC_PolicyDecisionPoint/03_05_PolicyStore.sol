// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./SecurityTypes.sol";

interface PolicyStore {
    function fetchPolicy(bytes32 resource, bytes32 action) external view returns (SecurityTypes.Policy memory);
    function fetchRole(bytes32 role, address user) external view returns (SecurityTypes.Role memory);
    function fetchRoleMembers(bytes32 role) external view returns (address[] memory);
    function fetchUserRoles(address user) external view returns (bytes32[] memory);
    function hasRole(address user, bytes32 role) external view returns (bool);
}