// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function register(address registrant) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isRegistered(address addr) external returns (bool);
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
}