// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library MappingStorageSlot {
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

    // Getting address from the slot
    /**
     * @dev Returns an `AddressSlot` with member `value` located in a mapping at a `slot` with a address as `key`.
     */
    function getAddressSlot(bytes32 mappingSlot, address key) internal pure returns (AddressSlot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located in a mapping at a `slot` with a bool as `key`.
     */
    function getAddressSlot(bytes32 mappingSlot, bool key) internal pure returns (AddressSlot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located in a mapping at a `slot` with a bytes32 as `key`.
     */
    function getAddressSlot(bytes32 mappingSlot, bytes32 key) internal pure returns (AddressSlot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located in a mapping at a `slot` with a uint256 as `key`.
     */
    function getAddressSlot(bytes32 mappingSlot, uint256 key) internal pure returns (AddressSlot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }

    // Getting bool from the slot
    /**
     * @dev Returns an `BooleanSlot` with member `value` located in a mapping at a `slot` with a address as `key`.
     */
    function getBooleanSlot(bytes32 mappingSlot, address key) internal pure returns (BooleanSlot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }
    
    /**
     * @dev Returns an `BooleanSlot` with member `value` located in a mapping at a `slot` with a bool as `key`.
     */
    function getBooleanSlot(bytes32 mappingSlot, bool key) internal pure returns (BooleanSlot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located in a mapping at a `slot` with a bytes32 as `key`.
     */
    function getBooleanSlot(bytes32 mappingSlot, bytes32 key) internal pure returns (BooleanSlot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located in a mapping at a `slot` with a uint256 as `key`.
     */
    function getBooleanSlot(bytes32 mappingSlot, uint256 key) internal pure returns (BooleanSlot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }

    // Getting bytes32 from the slot
    /**
     * @dev Returns an `Bytes32Slot` with member `value` located in a mapping at a `slot` with a address as `key`.
     */
    function getBytes32Slot(bytes32 mappingSlot, address key) internal pure returns (Bytes32Slot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located in a mapping at a `slot` with a bool as `key`.
     */
    function getBytes32Slot(bytes32 mappingSlot, bool key) internal pure returns (Bytes32Slot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located in a mapping at a `slot` with a bytes32 as `key`.
     */
    function getBytes32Slot(bytes32 mappingSlot, bytes32 key) internal pure returns (Bytes32Slot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located in a mapping at a `slot` with a uint256 as `key`.
     */
    function getBytes32Slot(bytes32 mappingSlot, uint256 key) internal pure returns (Bytes32Slot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }

    // Getting uint256 from the slot
    /**
     * @dev Returns an `Uint256Slot` with member `value` located in a mapping at a `slot` with a address as `key`.
     */
    function getUint256Slot(bytes32 mappingSlot, address key) internal pure returns (Uint256Slot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }
    
    /**
     * @dev Returns an `Uint256Slot` with member `value` located in a mapping at a `slot` with a bool as `key`.
     */
    function getUint256Slot(bytes32 mappingSlot, bool key) internal pure returns (Uint256Slot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located in a mapping at a `slot` with a bytes32 as `key`.
     */
    function getUint256Slot(bytes32 mappingSlot, bytes32 key) internal pure returns (Uint256Slot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located in a mapping at a `slot` with a uint256 as `key`.
     */
    function getUint256Slot(bytes32 mappingSlot, uint256 key) internal pure returns (Uint256Slot storage r) {
        bytes32 slot = keccak256(abi.encode(key, mappingSlot));
        assembly {
            r.slot := slot
        }
    }
}