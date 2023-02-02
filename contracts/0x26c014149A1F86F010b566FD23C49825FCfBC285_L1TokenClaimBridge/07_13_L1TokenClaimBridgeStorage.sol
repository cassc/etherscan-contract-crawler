// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library L1TokenClaimBridgeStorage {
    bytes32 constant STORAGE_POSITION = keccak256("homage.l1TokenClaimBridge");

    struct Struct {
        address l1EventLogger;
        address l2TokenClaimBridge;
        address royaltyEngine;
    }

    function get() internal pure returns (Struct storage storageStruct) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            storageStruct.slot := position
        }
    }
}