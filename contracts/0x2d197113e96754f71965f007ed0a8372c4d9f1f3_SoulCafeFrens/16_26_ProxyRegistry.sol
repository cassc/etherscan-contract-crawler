// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

address constant OS_PROXY_REGISTRY_ADDRESS = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;