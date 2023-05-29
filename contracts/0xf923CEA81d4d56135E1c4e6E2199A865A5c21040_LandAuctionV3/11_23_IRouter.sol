// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRouter {
    function initialiseRequest(address, uint256, bytes32) external returns (bool);
}