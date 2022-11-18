// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
    mapping(address => bool) public contracts;
}