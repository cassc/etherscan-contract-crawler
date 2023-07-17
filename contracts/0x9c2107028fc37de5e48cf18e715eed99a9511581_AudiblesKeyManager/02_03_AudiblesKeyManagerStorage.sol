// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract AudiblesKeyManagerProxyStorage {
    address public implementation;
    address public owner;
    address public audiblesContract;
}

abstract contract AudiblesKeyManagerStorage is AudiblesKeyManagerProxyStorage {
    uint16[5] public keysPerGrid;
    mapping(address => uint16) public keys;
    mapping(address => uint16) public phaseOneKeys;
    mapping(address => uint16) public phaseTwoKeys;
    mapping(address => bool) public uploadImageUnlocked;
}