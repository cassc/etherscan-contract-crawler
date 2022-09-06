// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant SAFE_OWNABLE_STORAGE_SLOT = keccak256("core.access.ownable.safe.storage");

struct SafeOwnableStorage {
    address nomineeOwner;
}

function safeOwnableStorage() pure returns (SafeOwnableStorage storage os) {
    bytes32 slot = SAFE_OWNABLE_STORAGE_SLOT;
    assembly {
        os.slot := slot
    }
}