// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UpgradeableBeacon} from  "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {BeaconProxy} from  "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {Ownable} from  "@openzeppelin/contracts/access/Ownable.sol";
import {IHotpot} from "./interface/IHotpot.sol";


contract HotpotFactory is Ownable {
    // Hotpot proxies
    address[] public hotpots;
    UpgradeableBeacon public beacon;

    constructor(address _implementation) {
        beacon = new UpgradeableBeacon(_implementation); // the Factory is the _owner of the beacon
    }

    function deployHotpot(IHotpot.InitializeParams calldata params) external onlyOwner returns(address) {
        bytes memory _data = abi.encodeWithSelector(IHotpot.initialize.selector, msg.sender, params);
        BeaconProxy _hotpot = new BeaconProxy(address(beacon), _data);
        hotpots.push(address(_hotpot));
        return address(_hotpot);
    }

    function upgradeImplementation(address _newImplementation) external onlyOwner {
        beacon.upgradeTo(_newImplementation);
    }

}