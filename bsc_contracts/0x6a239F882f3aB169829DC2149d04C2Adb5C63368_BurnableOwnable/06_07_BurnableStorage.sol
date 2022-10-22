// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library BurnableStorage {
    struct Layout {
        uint256 pausedUntil;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.Burnable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}