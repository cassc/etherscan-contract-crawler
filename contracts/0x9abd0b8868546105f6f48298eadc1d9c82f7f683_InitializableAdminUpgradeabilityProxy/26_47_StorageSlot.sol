pragma solidity ^0.6.0;

// SPDX-License-Identifier: GPL-3.0-only


/** @title Gets and sets parameters at a specified storage slot */
library StorageSlot {
    function _setStorageUint(bytes32 slot, uint256 data) internal {
        assembly {
            sstore(slot, data)
        }
    }

    function _getStorageUint(bytes32 slot) internal view returns (uint256) {
        uint256 result;
        assembly {
            result := sload(slot)
        }

        return result;
    }
}