// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library ERC20MetadataStorage {
    struct Layout {
        uint8 decimals;
        bool decimalsLocked;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.ERC20Metadata");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}