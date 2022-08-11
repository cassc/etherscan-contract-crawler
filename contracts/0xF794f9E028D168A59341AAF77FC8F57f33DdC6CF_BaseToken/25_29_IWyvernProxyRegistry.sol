// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IOwnableDelegateProxy {}

abstract contract IWyvernProxyRegistry {
    /* Authenticated proxies by user. */
    mapping(address => IOwnableDelegateProxy) public proxies;
    function registerProxy() public virtual returns (IOwnableDelegateProxy proxy);
}