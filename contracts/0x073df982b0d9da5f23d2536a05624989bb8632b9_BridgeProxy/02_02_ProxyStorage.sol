// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

contract ProxyStorage {
    address public implementation;
    address public admin;
    address public pendingAdmin;
}