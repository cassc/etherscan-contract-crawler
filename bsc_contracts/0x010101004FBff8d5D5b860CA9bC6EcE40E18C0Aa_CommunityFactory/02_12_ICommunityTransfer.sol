// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
* @title interface helps to transfer owners from factory to sender that produce instance
*/
interface ICommunityTransfer {
    function grantRoles(address[] memory accounts, uint8[] memory rolesIndexes) external;
}