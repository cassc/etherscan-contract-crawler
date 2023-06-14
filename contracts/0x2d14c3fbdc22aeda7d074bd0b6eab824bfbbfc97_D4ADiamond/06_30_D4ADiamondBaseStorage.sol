// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library D4ADiamondBaseStorage {
    struct Layout {
        bool initialized;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4A.contracts.storage.D4ADiamondBase");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}