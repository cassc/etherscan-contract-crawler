/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @title Storage
 * @author Theori, Inc.
 * @notice Helper functions for handling storage slot facts and computing storage slots
 */
library Storage {
    /**
     * @notice compute the slot for an element of a mapping
     * @param base the slot of the struct base
     * @param key the mapping key, padded to 32 bytes
     */
    function mapElemSlot(bytes32 base, bytes32 key) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(key, base));
    }

    /**
     * @notice compute the slot for an element of a static array
     * @param base the slot of the struct base
     * @param idx the index of the element
     * @param slotsPerElem the number of slots per element
     */
    function staticArrayElemSlot(
        bytes32 base,
        uint256 idx,
        uint256 slotsPerElem
    ) internal pure returns (bytes32) {
        return bytes32(uint256(base) + idx * slotsPerElem);
    }

    /**
     * @notice compute the slot for an element of a dynamic array
     * @param base the slot of the struct base
     * @param idx the index of the element
     * @param slotsPerElem the number of slots per element
     */
    function dynamicArrayElemSlot(
        bytes32 base,
        uint256 idx,
        uint256 slotsPerElem
    ) internal pure returns (bytes32) {
        return bytes32(uint256(keccak256(abi.encode(base))) + idx * slotsPerElem);
    }

    /**
     * @notice compute the slot for a struct field given the base slot and offset
     * @param base the slot of the struct base
     * @param offset the slot offset in the struct
     */
    function structFieldSlot(
        bytes32 base,
        uint256 offset
    ) internal pure returns (bytes32) {
        return bytes32(uint256(base) + offset);
    }

    function _parseUint256(bytes memory data) internal pure returns (uint256) {
        return uint256(bytes32(data)) >> (256 - 8 * data.length);
    }

    /**
     * @notice parse a uint256 from storage slot bytes
     * @param data the storage slot bytes
     * @return address the parsed address
     */
    function parseUint256(bytes memory data) internal pure returns (uint256) {
        require(data.length <= 32, 'data is not a uint256');
        return _parseUint256(data);
    }

    /**
     * @notice parse a uint64 from storage slot bytes
     * @param data the storage slot bytes
     */
    function parseUint64(bytes memory data) internal pure returns (uint64) {
        require(data.length <= 8, 'data is not a uint64');
        return uint64(_parseUint256(data));
    }

    /**
     * @notice parse an address from storage slot bytes
     * @param data the storage slot bytes
     */
    function parseAddress(bytes memory data) internal pure returns (address) {
        require(data.length <= 20, 'data is not an address');
        return address(uint160(_parseUint256(data)));
    }
}