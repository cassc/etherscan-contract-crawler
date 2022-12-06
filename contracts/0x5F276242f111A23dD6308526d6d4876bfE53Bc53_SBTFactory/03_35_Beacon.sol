// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Beacon is Ownable {
    UpgradeableBeacon private immutable _beacon;
    address public implementationContract;

    event BeaconUpgradedTo(address oldImpl, address newImpl);

    constructor(address impl) {
        _beacon = new UpgradeableBeacon(impl);
        implementationContract = impl;
    }

    function updateContract(address impl) public onlyOwner {
        _beacon.upgradeTo(impl);
        emit BeaconUpgradedTo(implementationContract, impl);
        implementationContract = impl;
    }

    function implementation() public view returns (address) {
        return _beacon.implementation();
    }
}