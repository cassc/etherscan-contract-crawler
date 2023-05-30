// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}