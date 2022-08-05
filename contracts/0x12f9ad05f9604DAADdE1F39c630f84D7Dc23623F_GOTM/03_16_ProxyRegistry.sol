// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity >=0.4.13;

import "./OwnableDelegateProxy.sol";

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}