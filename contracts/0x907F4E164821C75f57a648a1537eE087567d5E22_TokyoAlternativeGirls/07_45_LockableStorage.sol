// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

enum LockStatus {
    UnSet,
    UnLock,
    Lock
}

library LockableStorage {

    struct Layout {
        // Flag of restriction by lock.
        bool lockEnabled; // = true;
        // Default lock status.
        LockStatus defaultLock; // = LockStatus.UnLock;
        // Contract lock status. If true, all tokens are locked.
        LockStatus contractLock;
        // Lock status of token ID
        mapping(uint256 => LockStatus) tokenLock;
        // Lock status of wallet address
        mapping(address => LockStatus) walletLock;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256('Lockable.contracts.storage.facet');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}