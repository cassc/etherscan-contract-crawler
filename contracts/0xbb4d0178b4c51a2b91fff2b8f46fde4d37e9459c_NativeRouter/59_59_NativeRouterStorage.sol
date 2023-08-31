// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

// just a placeholder now in case there is any future state variables
abstract contract NativeRouterStorage {
    address public widgetFeeSigner;
    address public pauser;
    mapping(address => bool) public contractCallerWhitelist;
    bool public contractCallerWhitelistEnabled;
    uint256[97] private __gap;
}