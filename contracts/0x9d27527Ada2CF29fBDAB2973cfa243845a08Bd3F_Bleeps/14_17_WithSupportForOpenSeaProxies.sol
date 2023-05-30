// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract WithSupportForOpenSeaProxies {
    address internal immutable _proxyRegistryAddress;

    constructor(address proxyRegistryAddress) {
        _proxyRegistryAddress = proxyRegistryAddress;
    }

    function _isOpenSeaProxy(address owner, address operator) internal view returns (bool) {
        if (_proxyRegistryAddress == address(0)) {
            return false;
        }
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        return address(proxyRegistry.proxies(owner)) == operator;
    }
}