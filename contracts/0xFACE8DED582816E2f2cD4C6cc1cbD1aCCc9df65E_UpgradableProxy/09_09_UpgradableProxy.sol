// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol"; 

contract UpgradableProxy is TransparentUpgradeableProxy {
    constructor(address proxyAdmin, address implementation, bytes memory data) TransparentUpgradeableProxy(implementation, proxyAdmin, data) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
    }
}