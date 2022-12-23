// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StorageSlot {
    function setUint256(bytes32 slot, uint256 value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function getUint256(bytes32 slot) internal view returns (uint256 value) {
        assembly {
            value := sload(slot)
        }
    }

    function setAddress(bytes32 slot, address value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function getAddress(bytes32 slot) internal view returns (address value) {
        assembly {
            value := sload(slot)
        }
    }

    function setBool(bytes32 slot, bool value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function getBool(bytes32 slot) internal view returns (bool value) {
        assembly {
            value := sload(slot)
        }
    }
}