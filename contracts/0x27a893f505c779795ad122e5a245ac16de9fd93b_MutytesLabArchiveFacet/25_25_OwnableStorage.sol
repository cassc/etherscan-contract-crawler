// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant OWNABLE_STORAGE_SLOT = keccak256("core.access.ownable.storage");

struct OwnableStorage {
    address owner;
}

function ownableStorage() pure returns (OwnableStorage storage os) {
    bytes32 slot = OWNABLE_STORAGE_SLOT;
    assembly {
        os.slot := slot
    }
}