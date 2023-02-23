// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.8;

import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {UpgradeableBeaconProxy} from "./UpgradeableBeaconProxy.sol";
import {UpgradeableBeacon} from "openzeppelin-contracts/proxy/beacon/UpgradeableBeacon.sol";
import {Vm} from "forge-std/Vm.sol";

contract DeployProxy {
    ProxyType public proxyType;

    address public proxyAddress;

    address public beaconAddress;

    ERC1967Proxy public erc1967;

    ERC1967Proxy public uups;

    UpgradeableBeacon public beacon;

    UpgradeableBeaconProxy public beaconProxy;

    enum ProxyType {
        UUPS,
        BeaconProxy,
        Beacon,
        Transparent
    }

    function deploy(address implementation) public returns (address) {
        if (proxyType == ProxyType.Transparent) {
            revert("Transparent proxy returns a single address");
        } else if (proxyType == ProxyType.UUPS) {
            bytes memory data;
            return deployUupsProxy(implementation, data);
        } else if (proxyType == ProxyType.BeaconProxy) {
            bytes memory data;
            return deployBeaconProxy(implementation, data);
        } else if (proxyType == ProxyType.Beacon) {
            return deployBeacon(implementation);
        } else {
            revert("Undefined proxy");
        }
    }

    function deploy(address implementation, bytes memory data) public returns (address) {
        if (proxyType == ProxyType.Transparent) {
            revert("proxy implementation does't include admin address");
        } else if (proxyType == ProxyType.UUPS) {
            return deployUupsProxy(implementation, data);
        } else if (proxyType == ProxyType.Beacon) {
            revert("proxy implementation does't include admin address");
        } else {
            revert("Undefined proxy");
        }
    }

    function deployBeacon(address impl) public returns (address) {
        beacon = new UpgradeableBeacon(impl);
        beaconAddress = address(beacon);

        return beaconAddress;
    }

    function deployBeaconProxy(address _beacon, bytes memory data) public returns (address) {
        beaconProxy = new UpgradeableBeaconProxy(_beacon, data);
        proxyAddress = address(beaconProxy);

        return proxyAddress;
    }

    function deployErc1967Proxy(address implementation, bytes memory data) public returns (address) {
        erc1967 = new ERC1967Proxy(implementation, data);
        proxyAddress = address(erc1967);

        return proxyAddress;
    }

    function deployUupsProxy(address implementation, bytes memory data) public returns (address) {
        uups = new ERC1967Proxy(implementation, data);
        proxyAddress = address(uups);

        return proxyAddress;
    }

    function setType(string memory _proxyType) public {
        if (keccak256(bytes(_proxyType)) == keccak256(bytes("uups"))) {
            proxyType = ProxyType.UUPS;
        } else if (keccak256(bytes(_proxyType)) == keccak256(bytes("beacon"))) {
            proxyType = ProxyType.Beacon;
        } else if (keccak256(bytes(_proxyType)) == keccak256(bytes("beaconProxy"))) {
            proxyType = ProxyType.BeaconProxy;
        } else if (keccak256(bytes(_proxyType)) == keccak256(bytes("transparent"))) {
            proxyType = ProxyType.Transparent;
        }
    }
}