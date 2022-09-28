// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IOperatorFilter {
    function mayTransfer(address operator) external view returns (bool);
}