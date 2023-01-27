// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ICheckRoleProxy {

    function checkRole(bytes32 role, address account) external;
}
