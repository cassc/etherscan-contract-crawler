// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title ProxyAddresses
 * @author Jeremy Guyet (@jguyet)
 * @dev Library to manage the storage of addresses for proxies.
 */
library ProxyAddresses {
    struct AddressSlot {
        address value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}