// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./BeaconProxy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BeaconFactory is Ownable {
    address public tokenBeacon;

    event NewCloneTicker(address _newClone, address _owner, string symbol);

    constructor() {}

    function setBeacon(address beacon) public onlyOwner {
        tokenBeacon = beacon;
    }

    function createContract(
        bytes memory _data,
        string memory symbol
    ) external returns (address) {
        BeaconProxy proxy = new BeaconProxy(tokenBeacon, _data);
        emit NewCloneTicker(address(proxy), msg.sender, symbol);
        return address(proxy);
    }
}