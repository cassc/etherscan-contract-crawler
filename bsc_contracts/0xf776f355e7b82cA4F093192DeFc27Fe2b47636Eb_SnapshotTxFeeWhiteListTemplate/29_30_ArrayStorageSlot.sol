// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ArrayStorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` that represent the array length`.
     */
    function length(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` that have the uint located at `slot` + `index`.
     */
    function getAddressSlot(bytes32 slot, uint index) internal view returns (AddressSlot storage r) {
        require(index >= 0 && index < length(slot).value, "ERROR: Out of bound");
        slot = bytes32(uint256(keccak256(abi.encode(slot))) + index);
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` that have the uint located at `slot` + `index`.
     */
    function getBooleanSlot(bytes32 slot, uint index) internal view returns (BooleanSlot storage r) {
        require(index >= 0 && index < length(slot).value, "ERROR: Out of bound");
        slot = bytes32(uint256(keccak256(abi.encode(slot))) + index);
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` that have the uint located at `slot` + `index`.
     */
    function getBytes32Slot(bytes32 slot, uint index) internal view returns (Bytes32Slot storage r) {
        require(index >= 0 && index < length(slot).value, "ERROR: Out of bound");
        slot = bytes32(uint256(keccak256(abi.encode(slot))) + index);
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` that have the uint located at `slot` + `index`.
     */
    function getUint256Slot(bytes32 slot, uint index) internal view returns (Uint256Slot storage r) {
        require(index >= 0 && index < length(slot).value, "ERROR: Out of bound");
        slot = bytes32(uint256(keccak256(abi.encode(slot))) + index);
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Push an address to the end of the array started at `slot`. Must be used knowing the array slot
     */
    function push(bytes32 slot, address value) internal {
        uint lastIndex = length(slot).value;
        length(slot).value += 1;
        getAddressSlot(slot, lastIndex).value = value;
    }

    /**
     * @dev Push an bool to the end of the array started at `slot`. Must be used knowing the array slot
     */
    function push(bytes32 slot, bool value) internal {
        uint lastIndex = length(slot).value;
        length(slot).value += 1;
        getBooleanSlot(slot, lastIndex).value = value;
    }

    /**
     * @dev Push an bytes32 to the end of the array started at `slot`. Must be used knowing the array slot
     */
    function push(bytes32 slot, bytes32 value) internal {
        uint lastIndex = length(slot).value;
        length(slot).value += 1;
        getBytes32Slot(slot, lastIndex).value = value;
    }

    /**
     * @dev Push an uint to the end of the array started at `slot`. Must be used knowing the array slot
     */
    function push(bytes32 slot, uint value) internal {
        uint lastIndex = length(slot).value;
        length(slot).value += 1;
        getUint256Slot(slot, lastIndex).value = value;
    }
}