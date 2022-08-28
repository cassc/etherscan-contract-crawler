// SPDX-License-Identifier: MIT
pragma solidity >0.8.8;

import "lib/openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";

contract nBeaconProxy is BeaconProxy {
    constructor(address beacon, bytes memory data) payable BeaconProxy(beacon, data) {}

    receive() external payable override {
        // Allow ETH transfers to succeed
    }
}