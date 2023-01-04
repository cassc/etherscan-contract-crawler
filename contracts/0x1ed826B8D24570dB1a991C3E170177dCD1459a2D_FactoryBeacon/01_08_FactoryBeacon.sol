// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./BeaconProxy.sol";

contract FactoryBeacon {
    address public immutable tokenBeacon;

    event NewCloneTicker(address _newClone, address _owner, string symbol);

    constructor(address beaconAddress) {
        tokenBeacon = beaconAddress;
    }

    function createContract(bytes memory _data, string memory symbol) external returns (address) {
        BeaconProxy proxy = new BeaconProxy(tokenBeacon, _data);
        emit NewCloneTicker(address(proxy), msg.sender, symbol);
        return address(proxy);
    }
}