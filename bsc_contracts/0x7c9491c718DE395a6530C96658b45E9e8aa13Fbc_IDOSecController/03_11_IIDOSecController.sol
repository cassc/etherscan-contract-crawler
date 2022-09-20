// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IIDOSecController {
    event NewIDOCreated(address indexed pool, address creator);

    function isOperator(address) external view returns (bool);

    function getFeeInfo() external view returns (address, uint256);
}