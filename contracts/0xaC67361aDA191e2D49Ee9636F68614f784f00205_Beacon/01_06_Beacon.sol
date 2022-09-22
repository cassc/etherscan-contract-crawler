// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Beacon is Ownable {
    UpgradeableBeacon immutable beacon;

    address public blueprint;

    constructor(address initBlueprint) {
        beacon = new UpgradeableBeacon(initBlueprint);
        blueprint = initBlueprint;
        transferOwnership(tx.origin);
    }

    function update(address newBlueprint) public onlyOwner {
        beacon.upgradeTo(newBlueprint);
        blueprint = newBlueprint;
    }

    function implementation() public view returns (address) {
        return beacon.implementation();
    }
}