//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

library ProxyStorage {

    bytes32 constant DATA_KEY = 0x21b00fb42ba9970a2143fc9fb216ce19c58db008c8d83ff3a715bbc79598d7f0;

    struct PendingUpgrade {
        address newLogic;
        bytes initData;
        uint upgradeAfter;
    }

    struct ProxyData {
        address logic;
        uint32 timelockSeconds;
        PendingUpgrade pendingUpgrade;
    }

    function load() internal pure returns (ProxyData storage ds) {
        assembly { ds.slot := DATA_KEY }
    }
}