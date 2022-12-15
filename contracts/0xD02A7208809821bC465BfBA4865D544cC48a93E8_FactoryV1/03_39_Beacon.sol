// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Beacon is Ownable {
    event BeaconUpgradedTo(address oldImpl, address newImpl);

    UpgradeableBeacon immutable beacon;

    constructor(address impl) {
        beacon = new UpgradeableBeacon(impl);
    }

    function updateContract(address impl) public onlyOwner {
        address oldImpl = beacon.implementation();
        beacon.upgradeTo(impl);
        emit BeaconUpgradedTo(oldImpl, impl);
    }

    function implementation() external view returns (address) {
        return beacon.implementation();
    }
}