// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title ProxyModes
 * @author Jeremy Guyet (@jguyet)
 * @dev Library to save booleans in specifical storage slot.
 */
library ProxyBool {
    struct BoolSlot {
        bool value;
    }

    /**
     * @dev Returns an `BoolSlot` with member `value` located at `slot`.
     */
    function getBoolSlot(bytes32 slot) internal pure returns (BoolSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}