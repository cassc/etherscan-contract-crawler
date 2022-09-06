//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IOperatorAccessControl {
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function isOperator(address account) external view returns (bool);

    function addOperator(address account) external;

    function revokeOperator(address account) external;
}