// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IOperatorFilter {
    error IllegalOperator();
    function mayTransfer(address operator) external view returns (bool);
}