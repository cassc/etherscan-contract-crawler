// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library QuantumBlackListStorage {
    struct Layout {
        mapping(address => bool) blackList;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("quantum.contracts.storage.quantumblacklist.v1");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}