// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IGrantRole {
    function grantRole(bytes32 role, address account) external;
}

interface IRevokeRole {
    function revokeRole(bytes32 role, address account) external;
}