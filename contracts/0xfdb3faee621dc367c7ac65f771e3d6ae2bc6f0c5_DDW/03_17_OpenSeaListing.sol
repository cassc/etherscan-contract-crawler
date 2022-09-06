// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4 < 0.9.0;

contract OwnableDelegateProxy { }

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}