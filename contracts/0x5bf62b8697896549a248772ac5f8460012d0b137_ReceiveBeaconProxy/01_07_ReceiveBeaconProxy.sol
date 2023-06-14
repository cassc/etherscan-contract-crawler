// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

/**
 * @dev Overriding Proxy's fallback function to allow it to receive ETH
 * @notice https://forum.openzeppelin.com/t/openzeppelin-upgradeable-contracts-affected-by-istanbul-hardfork/1616
 * @notice After Istanbul hardfork ZOS upgradable contracts were not able receive ETH with fallback functions
 * Hence, we have added a possible fix for this issue
 */
contract ReceiveBeaconProxy is BeaconProxy {
    /* solhint-disable no-empty-blocks */
    constructor(address beacon, bytes memory data) payable BeaconProxy(beacon, data) {
        // EMPTY
    }

    // @notice Not need to override `fallback`, as fallback function will always have msg.data

    /**
     * @notice Only receive ETH and dont delegate the calls.
     * This is done to receive ETH from thirdparty contracts like Compound.
     * Also `receive` function does not have `msg.data` value.
     */
    receive() external payable override {
        // EMPTY
    }
    /* solhint-enable no-empty-blocks */
}