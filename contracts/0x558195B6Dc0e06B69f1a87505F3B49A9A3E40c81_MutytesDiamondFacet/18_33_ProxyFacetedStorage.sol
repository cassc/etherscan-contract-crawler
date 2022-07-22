// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant FACETED_PROXY_STORAGE_SLOT = keccak256("core.proxy.faceted.storage");

struct SelectorInfo {
    bool isUpgradable;
    uint16 position;
    address implementation;
}

struct ImplementationInfo {
    uint16 position;
    uint16 selectorCount;
}

struct ProxyFacetedStorage {
    mapping(bytes4 => SelectorInfo) selectorInfo;
    bytes4[] selectors;
    mapping(address => ImplementationInfo) implementationInfo;
    address[] implementations;
}

function proxyFacetedStorage() pure returns (ProxyFacetedStorage storage ps) {
    bytes32 slot = FACETED_PROXY_STORAGE_SLOT;
    assembly {
        ps.slot := slot
    }
}