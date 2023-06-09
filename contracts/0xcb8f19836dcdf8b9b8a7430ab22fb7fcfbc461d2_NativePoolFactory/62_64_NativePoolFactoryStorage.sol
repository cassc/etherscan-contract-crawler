// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

abstract contract NativePoolFactoryStorage {
    address[] public poolArray;
    address public registry;
    mapping(address => bool) public pools;
    mapping(address => address) public treasuryToPool;
    mapping(address => bool) public isMultiPoolTreasury;
    address public poolImplementation;

    uint256[100] private __gap;
}