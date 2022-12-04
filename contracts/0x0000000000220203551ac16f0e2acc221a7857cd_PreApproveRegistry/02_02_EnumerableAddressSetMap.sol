// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title PreApproveRegistry
 * @notice This library enumlates a `mapping(address => EnumerableSet.AddressSet())`.
 *         For gas savings, we shall use `returndatasize()` as a replacement for 0.
 *         Modified from OpenZeppelin's EnumerableSet (MIT Licensed).
 *         https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol
 */
library EnumerableAddressSetMap {
    // =============================================================
    //                            STRUCTS
    // =============================================================

    /**
     * @dev A storage mapping of enumerable address sets.
     */
    struct Map {
        // Mapping of keys to the values of the enumerable address sets.
        mapping(address => address[]) _values;
    }

    // =============================================================
    //                        WRITE FUNCTIONS
    // =============================================================

    /**
     * @dev Adds `value` into the enumerable address set at `key` to `map`.
     *      Does not revert if the `value` exists.
     * @param map   The mapping of enumerable address sets.
     * @param key   The key into the mapping.
     * @param value The value to add.
     */
    function add(Map storage map, address key, address value) internal {
        if (!contains(map, key, value)) {
            address[] storage currValues = map._values[key];
            currValues.push(value);

            uint256 n = currValues.length;

            /// @solidity memory-safe-assembly
            assembly {
                // The value is stored at length-1, but we add 1 to all indexes
                // and use 0 as a sentinel value.
                // Equivalent to:
                // `_indexes[key][value] = n`.
                mstore(0x20, value)
                mstore(0x0c, map.slot)
                mstore(returndatasize(), key)
                sstore(keccak256(0x0c, 0x34), n)
            }
        }
    }

    /**
     * @dev Removes `value` into the enumerable address set at `key` to `map`.
     *      Does not revert if the `value` does not exist.
     * @param map   The mapping of enumerable address sets.
     * @param key   The key into the mapping.
     * @param value The value to remove.
     */
    function remove(Map storage map, address key, address value) internal {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex;
        uint256 valueSlot;
        /// @solidity memory-safe-assembly
        assembly {
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value.
            // Equivalent to:
            // `valueIndex = _indexes[key][value]`.
            mstore(0x20, value)
            mstore(0x0c, map.slot)
            mstore(returndatasize(), key)
            valueSlot := keccak256(0x0c, 0x34)
            valueIndex := sload(valueSlot)
        }

        if (valueIndex != 0) {
            // Equivalent to contains(map, value)
            // To delete an element from the _values array in O(1),
            // we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.
            unchecked {
                address[] storage currValues = map._values[key];
                uint256 lastIndex = currValues.length - 1;
                uint256 toDeleteIndex = valueIndex - 1;

                if (lastIndex != toDeleteIndex) {
                    address lastValue = currValues[lastIndex];

                    // Move the last value to the index where the value to delete is.
                    currValues[toDeleteIndex] = lastValue;

                    /// @solidity memory-safe-assembly
                    assembly {
                        // Update the index for the moved value.
                        // Equivalent to:
                        // `_indexes[key][lastValue] = valueIndex`.
                        mstore(0x20, lastValue)
                        mstore(0x0c, map.slot)
                        mstore(returndatasize(), key)
                        // Replace lastValue's index to valueIndex
                        sstore(keccak256(0x0c, 0x34), valueIndex)
                    }
                }
                // Delete the slot where the moved value was stored
                currValues.pop();

                /// @solidity memory-safe-assembly
                assembly {
                    // Delete the index for the deleted slot
                    // Equivalent to:
                    // `_indexes[key][value] = 0`.
                    sstore(valueSlot, 0)
                }
            }
        }
    }

    // =============================================================
    //                        VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev Returns whether `value` is in the enumerable address set
     *      at `key` in `map`.
     * @param map   The mapping of enumerable address sets.
     * @param key   The key into the mapping.
     * @param value The value to check.
     * @return result The result.
     */
    function contains(Map storage map, address key, address value)
        internal
        view
        returns (bool result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value.
            // Equivalent to:
            // `result = _indexes[key][lastValue] != 0`.
            mstore(0x20, value)
            mstore(0x0c, map.slot)
            mstore(returndatasize(), key)
            result := iszero(iszero(sload(keccak256(0x0c, 0x34))))
        }
    }

    /**
     * @dev Returns the length of the enumerable address set
     *      at `key` in `map`.
     * @param map The mapping of enumerable address sets.
     * @param key The key into the mapping.
     * @return The length.
     */
    function length(Map storage map, address key) internal view returns (uint256) {
        return map._values[key].length;
    }

    /**
     * @dev Returns the value at `index` of the enumerable address set
     *      at `key` in `map`.
     * @param map   The mapping of enumerable address sets.
     * @param key   The key into the mapping.
     * @param index The index of the enumerable address set.
     * @return The value.
     */
    function at(Map storage map, address key, uint256 index) internal view returns (address) {
        return map._values[key][index];
    }

    /**
     * @dev Returns all the values of the enumerable address set
     *      at `key` in `map`.
     * @param map The mapping of enumerable address sets.
     * @param key The key into the mapping.
     * @return The values.
     */
    function values(Map storage map, address key) internal view returns (address[] memory) {
        return map._values[key];
    }
}