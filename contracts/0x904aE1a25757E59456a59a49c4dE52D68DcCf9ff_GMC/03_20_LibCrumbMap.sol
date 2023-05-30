// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

using LibCrumbMap for LibCrumbMap.CrumbMap;


/// @notice Efficient crumb map library for mapping integers to crumbs.
/// @author phaze (https://github.com/0xPhaze)
/// @author adapted from Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibBytemap.sol)
library LibCrumbMap {
    struct CrumbMap {
        mapping(uint256 => uint256) map;
    }

    /* ------------- CrumbMap ------------- */

    function get(CrumbMap storage crumbMap, uint256 index) internal view returns (uint256 result) {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, shr(7, index))
            result := and(shr(shl(1, and(index, 0x7f)), sload(keccak256(0x00, 0x20))), 0x03)
        }
    }

    function get32BytesChunk(CrumbMap storage crumbMap, uint256 bytesIndex) internal view returns (uint256 result) {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, bytesIndex)
            result := sload(keccak256(0x00, 0x20))
        }
    }

    function set32BytesChunk(
        CrumbMap storage crumbMap,
        uint256 bytesIndex,
        uint256 value
    ) internal {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, bytesIndex)
            sstore(keccak256(0x00, 0x20), value)
        }
    }

    function set(
        CrumbMap storage crumbMap,
        uint256 index,
        uint256 value
    ) internal {
        require(value < 4);

        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, shr(7, index))
            let storageSlot := keccak256(0x00, 0x20)
            let shift := shl(1, and(index, 0x7f))
            // Unset crumb at index and store.
            let chunkValue := and(sload(storageSlot), not(shl(shift, 0x03)))
            // Set crumb to `value` at index and store.
            chunkValue := or(chunkValue, shl(shift, value))
            sstore(storageSlot, chunkValue)
        }
    }

    /* ------------- mapping(uint256 => uint256) ------------- */

    function get(mapping(uint256 => uint256) storage crumbMap, uint256 index) internal view returns (uint256 result) {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, shr(7, index))
            result := and(shr(shl(1, and(index, 0x7f)), sload(keccak256(0x00, 0x20))), 0x03)
        }
    }

    function get32BytesChunk(mapping(uint256 => uint256) storage crumbMap, uint256 bytesIndex) internal view returns (uint256 result) {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, bytesIndex)
            result := sload(keccak256(0x00, 0x20))
        }
    }

    function set32BytesChunk(
        mapping(uint256 => uint256) storage crumbMap,
        uint256 bytesIndex,
        uint256 value
    ) internal {
        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, bytesIndex)
            sstore(keccak256(0x00, 0x20), value)
        }
    }

    function set(
        mapping(uint256 => uint256) storage crumbMap,
        uint256 index,
        uint256 value
    ) internal {
        require(value < 4);

        assembly {
            mstore(0x20, crumbMap.slot)
            mstore(0x00, shr(7, index))
            let storageSlot := keccak256(0x00, 0x20)
            let shift := shl(1, and(index, 0x7f))
            // Unset crumb at index and store.
            let chunkValue := and(sload(storageSlot), not(shl(shift, 0x03)))
            // Set crumb to `value` at index and store.
            chunkValue := or(chunkValue, shl(shift, value))
            sstore(storageSlot, chunkValue)
        }
    }
}