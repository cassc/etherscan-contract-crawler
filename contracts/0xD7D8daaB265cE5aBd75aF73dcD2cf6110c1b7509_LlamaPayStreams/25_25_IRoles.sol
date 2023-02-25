// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint8 constant ROOT_ROLE_ID = 0;
uint8 constant ROLE_MANAGER_ROLE_ID = 1;
// The last possible role is an unassingable role which is dynamic
// and having it or not depends on whether the user is an owner in the Safe
uint8 constant SAFE_OWNER_ROLE_ID = 255;

bytes32 constant ONLY_ROOT_ROLE_AS_ADMIN = bytes32(uint256(1));
bytes32 constant NO_ROLE_ADMINS = bytes32(0);

interface IRoles {
    function roleExists(uint8 roleId) external view returns (bool);
    function hasRole(address user, uint8 roleId) external view returns (bool);
}