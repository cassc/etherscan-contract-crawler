// SPDX-License-Identifier: NONE
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Proxyv1 is TransparentUpgradeableProxy {
    constructor(address logic, address admin, bytes memory data) payable TransparentUpgradeableProxy(logic, admin, data) {}
}


abstract contract Proxiable is UUPSUpgradeable {
    function _authorizeUpgrade(address newImplementation) internal override {
        _beforeUpgrade(newImplementation);
    }

    function _beforeUpgrade(address newImplementation) internal virtual;
}

contract ChildOfProxiable is Proxiable {
    function _beforeUpgrade(address newImplementation) internal virtual override {}
}