// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ISimpleAccessControl {
    function accountsWithRole(bytes32 role)
        external
        view
        returns (address[] memory);

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}