// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library CPITStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256('valio.storage.CPIT');

    // solhint-disable-next-line ordering
    struct Layout {
        uint256 DEPRECATED_lockedUntil; // timestamp of when vault is locked until
        mapping(uint256 => uint) deviation; // deviation for each window
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            l.slot := slot
        }
    }
}