// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.6;

interface IConfigurationManager {
    event SetCap(address indexed target, uint256 value);
    event ParameterSet(address indexed target, bytes32 indexed name, uint256 value);

    error ConfigurationManager__InvalidCapTarget();

    function setParameter(
        address target,
        bytes32 name,
        uint256 value
    ) external;

    function getParameter(address target, bytes32 name) external view returns (uint256);

    function getGlobalParameter(bytes32 name) external view returns (uint256);

    function setCap(address target, uint256 value) external;

    function getCap(address target) external view returns (uint256);
}