// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma abicoder v2;

import '@openzeppelin/contracts/proxy/Proxy.sol';

import './VTableBeacon.sol';

/**
 * @title VTableBeaconProxy
 */
contract VTableBeaconProxy is Proxy {
    VTableBeacon public immutable beacon;

    constructor(VTableBeacon _beacon) {
        beacon = _beacon;
    }

    function _implementation() internal view virtual override returns (address module) {
        return beacon.implementation(msg.sig);
    }
}