// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}