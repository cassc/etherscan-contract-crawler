// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOperatorFilter {
    function mayTransfer(address operator) external view returns (bool);
}