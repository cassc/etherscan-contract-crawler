// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 <0.9.0;

import "./OwnableDelegateProxy.sol";

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}