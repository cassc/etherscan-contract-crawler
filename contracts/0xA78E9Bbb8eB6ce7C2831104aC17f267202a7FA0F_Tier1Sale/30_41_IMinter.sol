// SPDX-License-Identifier: MIT
// Taipe Experience Contracts
pragma solidity ^0.8.9;

interface IMinter {
    function mint(address owner) external returns (uint);
}