// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}