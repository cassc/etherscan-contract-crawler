// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToBytes32Map storage map, bytes32 key, bytes32 value) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToBytes32Map storage map) internal view returns (bytes32[] memory) {
        return map._keys.values();
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToUintMap storage map, uint256 key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToUintMap storage map, uint256 key, string memory errorMessage) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToUintMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(UintToAddressMap storage map) internal view returns (uint256[] memory) {
        bytes32[] memory store = keys(map._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToUintMap storage map, address key, uint256 value) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(AddressToUintMap storage map) internal view returns (address[] memory) {
        bytes32[] memory store = keys(map._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(Bytes32ToUintMap storage map, bytes32 key, uint256 value) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the map. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }

    /**
     * @dev Return the an array containing all the keys
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function keys(Bytes32ToUintMap storage map) internal view returns (bytes32[] memory) {
        bytes32[] memory store = keys(map._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

interface Types {
    enum CallType {
        STATICCALL,
        DELEGATECALL,
        CALL
    }

    struct Executable {
        CallType callType;
        address target;
        uint256 value;
        bytes data;
    }

    struct TokenRequest {
        address token;
        uint256 amount;
    }
}

library TokenTransfer {
    error InvalidTarget();

    /**
     * @notice Builds a transfer executable for ERC20 tokens
     * @param token address of token
     * @param recipient address of recipient
     * @param amount amount of tokens to transfer
     */
    function _erc20TransferExec(address token, address recipient, uint256 amount)
        internal
        pure
        returns (Types.Executable memory)
    {
        if (token == address(0)) revert InvalidTarget();
        return Types.Executable({
            callType: Types.CallType.CALL,
            target: token,
            data: abi.encodeCall(IERC20.transfer, (recipient, amount)),
            value: 0
        });
    }

    /**
     * @notice Builds a transfer executable for native tokens
     * @param recipient address of recipient
     * @param amount amount of native tokens to transfer
     */
    function _nativeTransferExec(address recipient, uint256 amount) internal pure returns (Types.Executable memory) {
        if (recipient == address(0)) revert InvalidTarget();
        return Types.Executable({callType: Types.CallType.CALL, target: recipient, data: bytes(""), value: amount});
    }
}

interface IStrategy {
    function strategyName() external view returns (string memory); // Must be unique

    function getTriggerExecs(bytes32 automationId, address wallet) external view returns (Types.Executable[] memory);

    function getActionExecs(bytes32 automationId, address wallet) external view returns (Types.Executable[] memory);

    /**
     * @notice Returns true if the strategy can execute the automation
     *
     * @dev Every strategy must implement this function
     *  The strategy uses call type and target to determine if
     *  the automation can be executed.
     *  This is to ensure only specific target contracts can be
     *  called by the automation on the subAccount.
     *
     * @param callType CallType of the automation
     * @param target Target of the automation
     * @param subAccount SubAccount where automation is to be executed
     */
    function isExecutionAllowed(Types.CallType callType, address target, address subAccount)
        external
        view
        returns (bool);
}

interface IAddressProviderService {
    /// @notice Returns the address of the AddressProvider
    function addressProviderTarget() external view returns (address);
}

/**
 * @title CoreAuth
 * @notice Contains core authorization logic
 */
contract CoreAuth {
    error NotGovernance(address);
    error NotPendingGovernance(address);
    error NullAddress();

    event GovernanceTransferRequested(address indexed previousGovernance, address indexed newGovernance);
    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);
    event GuardianUpdated(address indexed previousGuardian, address indexed newGuardian);
    event FundManagerUpdated(address indexed previousFundManager, address indexed newFundManager);

    /**
     * @notice Governance
     */
    address public governance;

    /**
     * @notice PendingGovernance - used for transferring governance in a 2 step process
     */
    address public pendingGovernance;

    /**
     * @notice Guardian - has authority to pause the safe module execution
     */
    address public guardian;

    /**
     * @notice FundManager - responsible for funding keeper bots and target for payable execution fees
     */
    address public fundManager;

    constructor(address _governance, address _guardian, address _fundManager) {
        _notNull(_governance);
        _notNull(_guardian);
        _notNull(_fundManager);
        governance = _governance;
        guardian = _guardian;
        fundManager = _fundManager;
    }

    /**
     * @notice Guardian setter
     */
    function setGuardian(address _newGuardian) external {
        _notNull(_newGuardian);
        _onlyGov();
        emit GuardianUpdated(guardian, _newGuardian);
        guardian = _newGuardian;
    }

    /**
     * @notice FundManager setter
     */
    function setFundManager(address _newFundManager) external {
        _notNull(_newFundManager);
        _onlyGov();
        emit FundManagerUpdated(fundManager, _newFundManager);
        fundManager = _newFundManager;
    }

    /**
     * @notice Governance setter
     */
    function setGovernance(address _newGovernance) external {
        _notNull(_newGovernance);
        _onlyGov();
        emit GovernanceTransferRequested(governance, _newGovernance);
        pendingGovernance = _newGovernance;
    }

    /**
     * @notice Governance accepter
     */
    function acceptGovernance() external {
        if (msg.sender != pendingGovernance) {
            revert NotPendingGovernance(msg.sender);
        }
        emit GovernanceTransferred(governance, msg.sender);
        governance = msg.sender;
        delete pendingGovernance;
    }

    /**
     * @notice helper function to check if msg.sender is governance
     */
    function _onlyGov() internal view {
        if (msg.sender != governance) revert NotGovernance(msg.sender);
    }

    /**
     * @notice helper function to check if address is null
     */
    function _notNull(address addr) internal pure {
        if (addr == address(0)) revert NullAddress();
    }
}

/**
 * @title AddressProvider
 * @notice Stores addresses of external contracts and core components
 */
contract AddressProvider is CoreAuth {
    enum RegistryKey {
        STRATEGY,
        SUBSCRIPTION,
        SUBACCOUNT,
        WALLET_ADAPTER,
        WALLET
    }

    error AddressProviderUnsupported();
    error AlreadyInitialised();
    error RegistryKeyNotFound(uint8);

    event RegistryInitialised(address indexed registry, uint8 indexed registryKey);

    constructor(address _governance, address _guardian, address _fundManager)
        CoreAuth(_governance, _guardian, _fundManager)
    {}

    /**
     * @dev External contract addresses for Gnosis Safe deployments
     *     Can be updated by governance
     */
    address public gnosisProxyFactory;
    address public gnosisSafeSingleton;
    address public gnosisFallbackHandler;
    address public gnosisMultiSend;

    /**
     * @dev Registry contracts containing state
     *     Cannot be updated
     */
    address public strategyRegistry;
    address public subscriptionRegistry;
    address public subAccountRegistry;
    address public walletAdapterRegistry;
    address public walletRegistry;

    /**
     * @dev Contract addresses for core components
     *     Can be updated by governance
     */
    address public botManager;
    address public brahRouter;
    address public priceFeedManager;
    address public safeDeployer;

    function setGnosisProxyFactory(address _gnosisProxyFactory) external {
        _notNull(_gnosisProxyFactory);
        _onlyGov();
        gnosisProxyFactory = (_gnosisProxyFactory);
    }

    function setGnosisSafeSingleton(address _gnosisSafeSingleton) external {
        _notNull(_gnosisSafeSingleton);
        _onlyGov();
        gnosisSafeSingleton = (_gnosisSafeSingleton);
    }

    /// @dev Fallback handler can be null
    function setGnosisSafeFallbackHandler(address _gnosisFallbackHandler) external {
        _onlyGov();
        gnosisFallbackHandler = (_gnosisFallbackHandler);
    }

    function setGnosisMultiSend(address _gnosisMultiSend) external {
        _notNull(_gnosisMultiSend);
        _onlyGov();
        gnosisMultiSend = (_gnosisMultiSend);
    }

    /**
     * @dev CAUTION! Changing BotManager will break existing tasks
     *     and wont allow deletion of previously created tasks
     */
    function setBotManager(address _botManager) external {
        _onlyGov();
        _supportsAddressProvider(_botManager);
        botManager = (_botManager);
    }

    /**
     * @dev CAUTION! Changing PriceFeedManager will require adding price
     *      feeds for all existing tokens
     */
    function setPriceFeedManager(address _priceFeedManager) external {
        _onlyGov();
        _supportsAddressProvider(_priceFeedManager);
        priceFeedManager = _priceFeedManager;
    }

    /**
     * @dev CAUTION! Changing BrahRouter will require all existing wallets
     *     to re register new BrahRouter as a safe module
     */
    function setBrahRouter(address _brahRouter) external {
        _onlyGov();
        _supportsAddressProvider(_brahRouter);
        brahRouter = (_brahRouter);
    }

    /**
     * @dev CAUTION! Changing SafeDeployer will loose any existing
     *     reserve subAccounts present
     */
    function setSafeDeployer(address _safeDeployer) external {
        _onlyGov();
        _supportsAddressProvider(_safeDeployer);
        safeDeployer = (_safeDeployer);
    }

    /**
     * @notice Initialises a registry contract
     * @dev Ensures that the registry contract is not already initialised
     *  CAUTION! Does not check if registry contract is valid or supports AddressProviderService
     *  This is to enable the registry contract to be initialised before their deployment
     * @param key RegistryKey
     * @param _newAddress Address of the registry contract
     */
    function initRegistry(RegistryKey key, address _newAddress) external {
        _onlyGov();
        if (key == RegistryKey.STRATEGY) {
            _firstInit(address(strategyRegistry));
            strategyRegistry = (_newAddress);
        } else if (key == RegistryKey.SUBSCRIPTION) {
            _firstInit(address(subscriptionRegistry));
            subscriptionRegistry = (_newAddress);
        } else if (key == RegistryKey.SUBACCOUNT) {
            _firstInit(address(subAccountRegistry));
            subAccountRegistry = (_newAddress);
        } else if (key == RegistryKey.WALLET_ADAPTER) {
            _firstInit(address(walletAdapterRegistry));
            walletAdapterRegistry = (_newAddress);
        } else if (key == RegistryKey.WALLET) {
            _firstInit(address(walletRegistry));
            walletRegistry = (_newAddress);
        } else {
            revert RegistryKeyNotFound(uint8(key));
        }

        emit RegistryInitialised(_newAddress, uint8(key));
    }

    /**
     * @notice Ensures that the new address supports the AddressProviderService interface
     * and is pointing to this AddressProvider
     */
    function _supportsAddressProvider(address _newAddress) internal view {
        if (IAddressProviderService(_newAddress).addressProviderTarget() != address(this)) {
            revert AddressProviderUnsupported();
        }
    }

    /**
     * @notice Ensures that the registry is not already initialised
     */
    function _firstInit(address _existingAddress) internal pure {
        if (_existingAddress != address(0)) revert AlreadyInitialised();
    }
}

/**
 * @title AddressProviderService
 * @notice Provides a base contract for services that require access to the AddressProvider
 * @dev This contract is designed to be inheritable by other contracts
 *  Provides quick and easy access to all contracts in Console Ecosystem
 */
abstract contract AddressProviderService is IAddressProviderService {
    error InvalidAddressProvider();
    error NotGovernance(address);
    error InvalidAddress();

    AddressProvider public immutable addressProvider;
    address public immutable strategyRegistry;
    address public immutable subscriptionRegistry;
    address public immutable subAccountRegistry;
    address public immutable walletAdapterRegistry;
    address public immutable walletRegistry;

    constructor(address _addressProvider) {
        if (_addressProvider == address(0)) revert InvalidAddressProvider();
        addressProvider = AddressProvider(_addressProvider);
        strategyRegistry = addressProvider.strategyRegistry();
        _notNull(strategyRegistry);
        subscriptionRegistry = addressProvider.subscriptionRegistry();
        _notNull(subscriptionRegistry);
        subAccountRegistry = addressProvider.subAccountRegistry();
        _notNull(subAccountRegistry);
        walletAdapterRegistry = addressProvider.walletAdapterRegistry();
        _notNull(walletAdapterRegistry);
        walletRegistry = addressProvider.walletRegistry();
        _notNull(walletRegistry);
    }

    /**
     * @inheritdoc IAddressProviderService
     */
    function addressProviderTarget() external view override returns (address) {
        return address(addressProvider);
    }

    /**
     * @notice Checks if msg.sender is governance
     */
    function _onlyGov() internal view {
        if (msg.sender != addressProvider.governance()) {
            revert NotGovernance(msg.sender);
        }
    }

    function _notNull(address _addr) internal pure {
        if (_addr == address(0)) revert InvalidAddress();
    }
}

interface IWalletAdapter is Types {
    function id() external view returns (uint8);

    function formatForWallet(address _wallet, Types.Executable memory _txn)
        external
        view
        returns (Types.Executable memory);

    function isAuthorized(address _wallet, address _user) external view returns (bool);

    function decodeReturnData(bytes memory data) external view returns (bool success, bytes memory returnData);
}

/**
 * @title StrategyRegistry
 * @notice Stores address for strategies
 */
contract StrategyRegistry is AddressProviderService {
    event StrategyRegistered(address strategyAddress);
    event StrategyDeregistered(address strategyAddress);

    error AddressProviderUnsupported();

    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    mapping(address strategyAddress => bool isRegistered) public isStrategySupported;

    /**
     * @notice Registers strategy
     * @dev Only governance can call this function
     */
    function registerStrategy(address _strategyAddress) external {
        _onlyGov();
        _supportsAddressProvider(_strategyAddress);
        _registerStrategy(_strategyAddress, true);

        emit StrategyRegistered(_strategyAddress);
    }

    /**
     * @notice De-registers strategy
     * @dev Only governance can call this function
     */
    function deregisterStrategy(address _strategyAddress) external {
        _onlyGov();

        _registerStrategy(_strategyAddress, false);

        emit StrategyDeregistered(_strategyAddress);
    }

    function _registerStrategy(address _strategyAddress, bool register) internal {
        isStrategySupported[_strategyAddress] = register;
    }

    /**
     * @notice Ensures that the new address supports the AddressProviderService interface
     * and is pointing to this AddressProvider
     */
    function _supportsAddressProvider(address _newAddress) internal view {
        if (AddressProviderService(_newAddress).addressProviderTarget() != address(addressProvider)) {
            revert AddressProviderUnsupported();
        }
    }
}

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

interface IGnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        returns (bool success, bytes memory returnData);

    function isOwner(address owner) external view returns (bool);
    function nonce() external view returns (uint256);
    function getThreshold() external view returns (uint256);
    function isModuleEnabled(address module) external view returns (bool);
    function enableModule(address module) external;
    function removeOwner(address prevOwner, address owner, uint256 _threshold) external;
    function swapOwner(address prevOwner, address oldOwner, address newOwner) external;
    function getOwners() external view returns (address[] memory);

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable returns (bool);

    function setup(
        address[] memory _owners,
        uint256 _threshold,
        address to,
        bytes memory data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address paymentReceiver
    ) external;

    function addOwnerWithThreshold(address owner, uint256 _threshold) external;
}

interface IGnosisProxyFactory {
    event ProxyCreation(address proxy, address singleton);

    function calculateCreateProxyWithNonceAddress(address _singleton, bytes memory initializer, uint256 saltNonce)
        external
        returns (address proxy);

    function createProxy(address singleton, bytes memory data) external returns (address proxy);

    function createProxyWithCallback(address _singleton, bytes memory initializer, uint256 saltNonce, address callback)
        external
        returns (address proxy);

    function createProxyWithNonce(address _singleton, bytes memory initializer, uint256 saltNonce)
        external
        returns (address proxy);

    function proxyCreationCode() external pure returns (bytes memory);

    function proxyRuntimeCode() external pure returns (bytes memory);
}

interface IGnosisMultiSend {
    function multiSend(bytes memory transactions) external payable;
}

library SafeHelper {
    error InvalidMultiSendCall(uint256);
    error InvalidMultiSendInput();
    error SafeExecTransactionFailed();

    /**
     * @notice Executes a transaction on a safe
     *
     * @dev Allows any contract using this library to execute a transaction on a safe
     *  Assumes the contract using this method is the owner of the safe
     *  Also assumes the safe is a single threshold safe
     *  This uses pre-validated signature scheme used by gnosis
     *
     * @param safe Safe address
     * @param target Target contract address
     * @param op Safe Operation type
     * @param data Transaction data
     */
    function _executeOnSafe(address safe, address target, Enum.Operation op, bytes memory data) internal {
        bool success = IGnosisSafe(safe).execTransaction(
            address(target), // to
            0, // value
            data, // data
            op, // operation
            0, // safeTxGas
            0, // baseGas
            0, // gasPrice
            address(0), // gasToken
            payable(address(0)), // refundReceiver
            _generateSingleThresholdSignature(address(this)) // signatures
        );

        if (!success) revert SafeExecTransactionFailed();
    }

    /**
     * @notice Generates a pre-validated signature for a safe transaction
     * @dev Refer to https://docs.safe.global/learn/safe-core/safe-core-protocol/signatures#pre-validated-signatures
     * @param owner Owner of the safe
     */
    function _generateSingleThresholdSignature(address owner) internal pure returns (bytes memory) {
        bytes memory signatures = abi.encodePacked(
            bytes12(0), // Padding for signature verifier address
            bytes20(owner), // Signature Verifier
            bytes32(0), // Position of extra data bytes (last set of data)
            bytes1(hex"01") // Signature Type - 1 (presigned transaction)
        );
        return signatures;
    }

    /**
     * @notice Packs multiple executables into a single bytes array compatible with Safe's MultiSend contract
     * @dev Reference contract at https://github.com/safe-global/safe-contracts/blob/main/contracts/libraries/MultiSend.sol
     * @param _txns Array of executables to pack
     */
    function _packMultisendTxns(Types.Executable[] memory _txns) internal pure returns (bytes memory packedTxns) {
        uint256 len = _txns.length;
        if (len == 0) revert InvalidMultiSendInput();

        uint256 i = 0;
        do {
            // Enum.Operation.Call is 0
            uint8 call = uint8(Enum.Operation.Call);
            if (_txns[i].callType == Types.CallType.DELEGATECALL) {
                call = uint8(Enum.Operation.DelegateCall);
            } else if (_txns[i].callType == Types.CallType.STATICCALL) {
                revert InvalidMultiSendCall(i);
            }

            uint256 calldataLength = _txns[i].data.length;

            bytes memory encodedTxn = abi.encodePacked(
                bytes1(call), bytes20(_txns[i].target), bytes32(_txns[i].value), bytes32(calldataLength), _txns[i].data
            );

            if (i != 0) {
                // If not first transaction, append to packedTxns
                packedTxns = abi.encodePacked(packedTxns, encodedTxn);
            } else {
                // If first transaction, set packedTxns to encodedTxn
                packedTxns = encodedTxn;
            }

            unchecked {
                ++i;
            }
        } while (i < len);
    }
}

/**
 * @title WalletAdapterRegistry
 * @notice Stores address for wallet adapters of each wallet type
 */
contract WalletAdapterRegistry is AddressProviderService {
    error InvalidWalletId();

    event WalletAdapterRegistered(address indexed adapterAddress, uint8 indexed walletType);

    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    mapping(uint8 walletType => address adapterAddress) public walletAdapter;

    /**
     * @notice Registers wallet adapter for a wallet type
     *
     * @dev Only governance can call this function
     *  Can be used to upgrade wallet adapter
     *
     * @param _adapter address of wallet adapter
     */
    function registerWalletAdapter(address _adapter) external {
        _onlyGov();
        uint8 _walletId = IWalletAdapter(_adapter).id();

        if (_walletId == 0) revert InvalidWalletId();

        walletAdapter[_walletId] = _adapter;

        emit WalletAdapterRegistered(_adapter, _walletId);
    }

    /**
     * @notice Checks if wallet adapter is registered for a wallet type
     * @param _walletType wallet type
     * @return true if wallet adapter is registered for a wallet type
     */
    function isWalletTypeSupported(uint8 _walletType) external view returns (bool) {
        if (walletAdapter[_walletType] == address(0)) return false;
        return true;
    }
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/// @notice chainlink aggregator interface
interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

/**
 * @title PriceFeedManager
 *   @notice Manages multiple tokens and their chainlink price feeds, for token price conversions
 */
contract PriceFeedManager is AddressProviderService {
    error NotUSDPriceFeed(address feed);
    error InvalidPriceFeed(address feed);
    error InvalidERC20Decimals(address token);
    error InvalidPriceFromRound(uint80 roundId);
    error InvalidWETHAddress();
    error PriceFeedStale();
    error TokenPriceFeedNotFound(address token);

    struct PriceFeedData {
        uint8 _tokenDecimals;
        address _address;
        uint64 _staleFeedThreshold;
    }

    /// @notice default stale threshold to price feeds on being added
    uint64 public constant DEFAULT_STALE_FEED_THRESHOLD = 90000;
    /// @notice address of ETH
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @notice address of WETH
    address public immutable WETH;

    /// @notice mapping of token address to data of price feed (_address, _staleFeedThreshold, _tokenDecimals)
    mapping(address token => PriceFeedData priceFeedData) public tokenPriceFeeds;

    constructor(address _addressProvider, address _weth) AddressProviderService(_addressProvider) {
        if (_weth == address(0)) revert InvalidWETHAddress();
        WETH = _weth;
    }

    /**
     * @notice Returns the pride feed data associated with a given token address
     * @param token address of token to get price feed data for
     * @return priceFeedData data of the price feed
     */
    function getPriceFeedData(address token) public view returns (PriceFeedData memory priceFeedData) {
        priceFeedData = tokenPriceFeeds[token];

        if (priceFeedData._address == address(0)) {
            revert TokenPriceFeedNotFound(token);
        }
    }

    /**
     * @notice Governance function to set the price feed for a token address
     * @param token address of a valid ERC20 token or native ETH
     * @param priceFeed address of a valid chainlink USD price feed
     * @param optionalStaleFeedThreshold optional stale feed threshold to set, defaults to 90000
     */
    function setTokenPriceFeed(address token, address priceFeed, uint64 optionalStaleFeedThreshold) external {
        _onlyGov();
        uint8 tokenDecimals = 0;

        try IAggregatorV3(priceFeed).decimals() returns (uint8 _decimals) {
            if (_decimals != 8) revert NotUSDPriceFeed(priceFeed);
        } catch {
            revert InvalidPriceFeed(priceFeed);
        }

        if (token != ETH) {
            try IERC20Metadata(token).decimals() returns (uint8 _decimals) {
                if (_decimals > 18) revert InvalidERC20Decimals(token);

                tokenDecimals = _decimals;
            } catch {
                revert InvalidERC20Decimals(token);
            }
        } else {
            tokenDecimals = 18;
        }

        if (optionalStaleFeedThreshold == 0) {
            optionalStaleFeedThreshold = DEFAULT_STALE_FEED_THRESHOLD;
        }

        try IAggregatorV3(priceFeed).latestRoundData() returns (
            uint80 roundId, int256 price, uint256, uint256 updatedAt, uint80 answeredInRound
        ) {
            _validateRound(roundId, answeredInRound, price, updatedAt, optionalStaleFeedThreshold);
        } catch {
            revert InvalidPriceFeed(priceFeed);
        }

        PriceFeedData storage priceFeedData = tokenPriceFeeds[token];
        priceFeedData._address = priceFeed;
        priceFeedData._staleFeedThreshold = optionalStaleFeedThreshold;
        priceFeedData._tokenDecimals = tokenDecimals;
    }

    /**
     * @notice Governance function to set the stake feed threshold of a given token
     * @param token address of token to modify stale feed threshold for
     * @param _staleFeedThreshold the stale feed threshold to set
     */
    function setTokenPriceFeedStaleThreshold(address token, uint64 _staleFeedThreshold) external {
        _onlyGov();

        PriceFeedData storage priceFeedData = tokenPriceFeeds[token];

        if (priceFeedData._address == address(0)) {
            revert TokenPriceFeedNotFound(token);
        }

        priceFeedData._staleFeedThreshold = _staleFeedThreshold;
    }

    /**
     * @notice Returns the token price given the token address
     * @param token address of token
     * @return price of token
     */
    function getTokenPrice(address token) external view returns (uint256 price) {
        (price,) = _getTokenData(token);
    }

    /**
     * @notice Returns the price of a token, in terms of another given token, provided both are added
     * @param amount amount of tokens in tokenX
     * @param tokenX address of token to convert from
     * @param tokenY address of token to convert to
     * @return price of tokenX amount in tokenY
     */
    function getTokenXPriceInY(uint256 amount, address tokenX, address tokenY) external view returns (uint256) {
        if ((tokenX == ETH || tokenX == WETH) && (tokenY == ETH || tokenY == WETH)) {
            return amount;
        }

        (uint256 tokenXPrice, uint8 tokenXDecimals) = _getTokenData(tokenX);
        (uint256 tokenYPrice, uint8 tokenYDecimals) = _getTokenData(tokenY);

        /// NOTE: returned price is adjusted to decimals of `tokenY`
        //  Representing decimal adjustment returning final amount in Y decimals
        //     (((     8      +     X       +       Y        )    -        8)   -      X)
        return (((tokenXPrice * amount * (10 ** tokenYDecimals)) / tokenYPrice) / (10 ** tokenXDecimals));
    }

    /**
     * @notice Internal helper to get the price and decimals of a token
     * @param token address of token
     * @return price of token
     * @return decimals of token
     */
    function _getTokenData(address token) internal view returns (uint256, uint8) {
        PriceFeedData memory priceFeedData = getPriceFeedData(token);

        (uint80 roundId, int256 _price,, uint256 updatedAt, uint80 answeredInRound) =
            IAggregatorV3(priceFeedData._address).latestRoundData();

        _validateRound(roundId, answeredInRound, _price, updatedAt, priceFeedData._staleFeedThreshold);

        return (uint256(_price), priceFeedData._tokenDecimals);
    }

    /**
     * @notice Internal helper to validate the latest round data of a chainlink price feed
     * @param roundId round id
     * @param answeredInRound round where latest returned data was answered
     * @param _latestPrice latest price from price feed
     * @param _lastUpdatedAt latest updated timestamp
     * @param _staleFeedThreshold stale feed threshold set for token
     */
    function _validateRound(
        uint80 roundId,
        uint80 answeredInRound,
        int256 _latestPrice,
        uint256 _lastUpdatedAt,
        uint256 _staleFeedThreshold
    ) internal view {
        if (_latestPrice <= 0) revert InvalidPriceFromRound(roundId);

        if (_lastUpdatedAt == 0) revert PriceFeedStale();

        if ((answeredInRound < roundId) || (block.timestamp - _lastUpdatedAt > _staleFeedThreshold)) {
            revert PriceFeedStale();
        }
    }
}

contract WalletRegistry is AddressProviderService {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    struct WalletData {
        uint8 walletType;
        address feeToken;
    }

    error WalletAlreadyExists(address);
    error UnsupportedWallet(address);
    error UnsupportedFeeToken(address);
    error TokenAlreadyAllowed(address);
    error WalletDoesntExist(address);

    event FeeTokenAdded(address indexed feeToken);
    event WalletRegistered(address indexed wallet, address indexed feeToken, uint8 walletType);
    event WalletDeRegistered(address indexed wallet);
    event WalletFeeTokenUpdated(address indexed wallet, address indexed feeToken);

    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    EnumerableMap.AddressToUintMap allowedFeeTokens;
    mapping(address wallet => WalletData walletData) internal _walletDataMap;

    /**
     * @notice Adds a fee token to allowed fee tokens
     * @dev Can be used to add new fee tokens
     *  Once added, a fee token cannot be removed due to potential
     *  conflict with existing wallet fee tokens
     * @param _feeToken address of fee token
     */
    function addFeeToken(address _feeToken) external {
        _onlyGov();

        /// @dev internally reverts if price feed is not found
        PriceFeedManager(addressProvider.priceFeedManager()).getPriceFeedData(_feeToken);

        // Enumerable map should return false if feeToken is already present
        if (!allowedFeeTokens.set(_feeToken, allowedFeeTokens.length())) {
            revert TokenAlreadyAllowed(_feeToken);
        }

        emit FeeTokenAdded(_feeToken);
    }

    /**
     * @notice Returns if a fee token is allowed
     * @param _feeToken address of fee token
     * @return bool indicating if a fee token is allowed
     */
    function isFeeTokenAllowed(address _feeToken) external view returns (bool) {
        return allowedFeeTokens.contains(_feeToken);
    }

    /**
     * @notice Registers a wallet with wallet type and preferred fee token
     * @dev This assumes brahRouter already has permissions to execute on this user
     *  In case of gnosis safe, it already is added as a safe module on safe
     *  msg.sender is wallet here
     * @param _walletType wallet type
     * @param _feeToken address of fee token
     */
    function registerWallet(uint8 _walletType, address _feeToken) external {
        if (isWallet(msg.sender)) revert WalletAlreadyExists(msg.sender);

        //checking if walletType is supported
        if (!WalletAdapterRegistry(walletAdapterRegistry).isWalletTypeSupported(_walletType)) {
            revert UnsupportedWallet(msg.sender);
        }

        _setFeeToken(msg.sender, _feeToken);
        _setWalletType(msg.sender, _walletType);

        emit WalletRegistered(msg.sender, _feeToken, _walletType);
    }

    /**
     * @notice De-registers a wallet
     * @dev Can only be called by wallet itself
     *  CAUTION: Calling this will cause console to be unusable
     *  and will break any existing subscriptions
     *  Funds can still be recovered from subaccounts
     *
     *  A user can deregister their wallet and register
     *  their wallet again with a different wallet type
     *  to change their wallet type
     */
    function deRegisterWallet() external {
        if (!isWallet(msg.sender)) revert WalletDoesntExist(msg.sender);
        delete _walletDataMap[msg.sender];
        emit WalletDeRegistered(msg.sender);
    }

    /**
     * @notice Sets fee token for wallet
     * @dev Can only be called by wallet itself
     * @param _token address of fee token
     */
    function setFeeToken(address _token) external {
        if (!isWallet(msg.sender)) revert WalletDoesntExist(msg.sender);
        _setFeeToken(msg.sender, _token);
        emit WalletFeeTokenUpdated(msg.sender, _token);
    }

    /**
     * @notice Checks if wallet is registered
     * @param _wallet address of wallet
     * @return bool
     */
    function isWallet(address _wallet) public view returns (bool) {
        WalletData storage walletData = _walletDataMap[_wallet];
        if (walletData.walletType == 0 || walletData.feeToken == address(0)) {
            return false;
        }
        return true;
    }

    /**
     * @notice Fetches wallet type for wallet
     * @param _wallet wallet address
     * @return uint8 wallet type
     */
    function walletType(address _wallet) external view returns (uint8) {
        return _walletDataMap[_wallet].walletType;
    }

    /**
     * @notice Fetches fee token for wallet
     * @param _wallet wallet address
     * @return address fee token
     */
    function walletFeeToken(address _wallet) external view returns (address) {
        return _walletDataMap[_wallet].feeToken;
    }

    /**
     * @notice sets wallet type
     */
    function _setWalletType(address _wallet, uint8 _walletType) private {
        _walletDataMap[_wallet].walletType = _walletType;
    }

    /**
     * @notice validates and sets fee token
     */
    function _setFeeToken(address _wallet, address _feeToken) internal {
        if (!allowedFeeTokens.contains(_feeToken)) {
            revert UnsupportedFeeToken(_feeToken);
        }
        _walletDataMap[_wallet].feeToken = _feeToken;
    }
}

/**
 * @title SafeWalletAdapter
 * @notice This contract implements the IWalletAdapter interface for Gnosis Safe wallets.
 * @dev This adapter enables the integration of Gnosis Safe wallets with other contracts.
 */
contract SafeWalletAdapter is IWalletAdapter {
    // Custom error for handling invalid operation enums
    error UnableToParseOperation();

    // Wallet adapter ID
    // @dev Do NOT change the ID of SafeWalletAdapter from 1.
    uint8 public constant override id = 1;

    /**
     * @notice Formats a transaction for a Gnosis Safe wallet.
     * @param _wallet Address of the Gnosis Safe wallet.
     * @param _txn Transaction to be formatted.
     * @return formattedTxn Formatted transaction for the Gnosis Safe wallet.
     */
    function formatForWallet(address _wallet, Types.Executable memory _txn)
        external
        pure
        override
        returns (Types.Executable memory formattedTxn)
    {
        // Create a formatted transaction executable by a safe module
        formattedTxn = Types.Executable({
            callType: CallType.CALL,
            target: _wallet,
            value: 0,
            data: abi.encodeCall(
                IGnosisSafe.execTransactionFromModuleReturnData,
                (_txn.target, _txn.value, _txn.data, parseOperationEnum(_txn.callType))
                )
        });
    }

    /**
     * @notice Decodes the return data of a transaction.
     * @param data The return data to be decoded.
     * @return success Boolean indicating if the transaction was successful.
     * @return returnData Decoded return data.
     */
    function decodeReturnData(bytes memory data)
        external
        pure
        override
        returns (bool success, bytes memory returnData)
    {
        (success, returnData) = abi.decode(data, (bool, bytes));
    }

    /**
     * @notice Checks if a user is authorized for a Gnosis Safe wallet.
     * @param _wallet Address of the Gnosis Safe wallet.
     * @param _user Address of the user to be checked for authorization.
     * @return True if the user is authorized, false otherwise.
     */
    function isAuthorized(address _wallet, address _user) external view override returns (bool) {
        // Return false if the wallet threshold is greater than 1
        if (IGnosisSafe(_wallet).getThreshold() > 1) return false;
        // Return true if the user is an owner of the Gnosis Safe wallet
        return IGnosisSafe(_wallet).isOwner(_user);
    }

    /**
     * @notice Converts a CallType enum to an Operation enum.
     * @dev Reverts with UnableToParseOperation error if the CallType is not supported.
     * @param callType The CallType enum to be converted.
     * @return operation The converted Operation enum.
     */
    function parseOperationEnum(CallType callType) public pure returns (Enum.Operation operation) {
        if (callType == CallType.DELEGATECALL) {
            operation = Enum.Operation.DelegateCall;
        } else if (callType == CallType.CALL) {
            operation = Enum.Operation.Call;
        } else {
            revert UnableToParseOperation();
        }
    }
}

/**
 * @title SafeDeployer
 * @notice This contract is responsible for deploying and configuring Gnosis Safe wallets.
 * @dev It supports deployment of console accounts and sub accounts,
 *  as well as maintaining a reserve of sub accounts
 *  The reserve subaccounts can be deployed in advance by anyone
 *  and serve as a mechanism to subsidize the cost of deploying new
 *  sub accounts and subscribing to strategies
 */
contract SafeDeployer is AddressProviderService {
    /**
     * @notice Emitted after the brah console is deployed for the owner.
     * @param owner The user address.
     * @param consoleAddress The console-safe deployed for user.
     */
    event brahConsoleDeployed(address indexed owner, address indexed consoleAddress);

    /**
     * @notice Emitted after a sub account is deployed for the console.
     * @param consoleAddress The console-safe address.
     * @param subAccountAddress The sub account deployed for console.
     */
    event subAccountAllocated(address indexed consoleAddress, address indexed subAccountAddress);

    error InvalidOwner();
    error OnlySubAccountRegistry();
    error OnlyOwner();

    string public constant VERSION = "1.04";

    address[] public subAccountReserve;

    mapping(address owner => uint96 safeCount) public ownerSafeCount;

    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    /**
     * @notice Deploys a console account for a user.
     *
     * @dev The console account in this case is a Gnosis Safe wallet.
     *  The console account is deployed with the user as the owner.
     *  BrahRouter is enabled as a safe module on the console account.
     *
     * @param _owner The address of the user.
     * @param _feeToken The address of the fee token.
     * @return The address of the deployed console account.
     */
    function deployConsoleAccount(address _owner, address _feeToken) external returns (address) {
        if (_owner != msg.sender) {
            revert OnlyOwner();
        }

        address safe = _createSafe(_owner);
        _setupSafeAsConsoleAccount(safe, _owner, _feeToken);

        emit brahConsoleDeployed(_owner, safe);
        return (safe);
    }

    /**
     * @notice Deploy reserve sub accounts.
     *
     *  @dev Can be used to deploy reserve sub accounts in batches.
     *  Useful when gasprice is low and we want to
     *  subsidize the cost of subscribing to deployments
     *
     * @param n The number of sub accounts to be deployed.
     */
    function deployReserveSubAccounts(uint256 n) external {
        uint256 idx = 0;
        while (idx < n) {
            subAccountReserve.push(_deployReserveSubAccount());
            unchecked {
                ++idx;
            }
        }
    }

    /**
     * @notice returns an array of the current reserve subAccounts
     *   @return list of reserve subAccount addresses
     */
    function getReserveSubAccounts() external view returns (address[] memory) {
        return subAccountReserve;
    }

    /**
     * @notice Allocate a fresh sub account.
     *
     * @dev Allocates a fresh sub account from the reserve.
     *  If no reserve sub accounts are available, deploys a new one.
     *  If a reserve sub account is available, transfers ownership to the wallet.
     *  Enables wallet as a safe module on the sub account.
     *  Subaccount returned should be equivalent to deploying a new sub account.
     *
     * @param _wallet The address of the main Safe.
     * @return subAccount address of the allocated sub account.
     */
    function allocateOrDeployFreshSubAccount(address _wallet) external returns (address subAccount) {
        // Only the sub account registry can call this method during createSubscription
        _onlySubAccountRegistry();

        // Checking if any reserve sub accounts are available
        uint256 subAccountsAvailable = subAccountReserve.length;

        // If reserve sub accounts are available, allocate one
        if (subAccountsAvailable > 0) {
            unchecked {
                subAccount = subAccountReserve[subAccountsAvailable - 1];
            }
            subAccountReserve.pop();

            Types.Executable[] memory transferOwnershipExecs = new Types.Executable[](2);

            // Enable mainSafe as a module on the sub account
            transferOwnershipExecs[0] = Types.Executable({
                callType: Types.CallType.CALL,
                target: subAccount,
                value: 0,
                data: abi.encodeCall(IGnosisSafe.enableModule, (_wallet))
            });
            // Replace the owner of the sub account with the mainSafe
            transferOwnershipExecs[1] = Types.Executable({
                callType: Types.CallType.CALL,
                target: subAccount,
                value: 0,
                data: abi.encodeCall(IGnosisSafe.swapOwner, (address(0x1), address(this), _wallet))
            });

            bytes memory multiSendCalldata = SafeHelper._packMultisendTxns(transferOwnershipExecs);

            // Execute the multisend transaction
            SafeHelper._executeOnSafe(
                subAccount,
                addressProvider.gnosisMultiSend(),
                Enum.Operation.DelegateCall,
                abi.encodeCall(IGnosisMultiSend.multiSend, multiSendCalldata)
            );
        } else {
            // If no reserve sub accounts are available, deploy a new sub account
            subAccount = _deploySubAccount(_wallet);
        }

        emit subAccountAllocated(_wallet, subAccount);
    }

    /**
     * @notice Internal function to deploy a reserve sub account.
     * @return The address of the deployed reserve sub account.
     */
    function _deployReserveSubAccount() internal returns (address) {
        address safe = _createSafe(address(this));
        _setupSafeAsReserveSubAccount(safe);
        return (safe);
    }

    /**
     * @notice Internal function to deploy a sub account.
     * @param _owner The address of the owner.
     * @return The address of the deployed sub account.
     */
    function _deploySubAccount(address _owner) internal returns (address) {
        address safe = _createSafe(_owner);
        _setupSafeAsSubAccount(safe, _owner);

        return (safe);
    }

    /**
     * @notice Internal function to create a new Gnosis Safe.
     * @param _owner The address of the Safe owner.
     * @return The address of the created Gnosis Safe.
     */
    function _createSafe(address _owner) internal returns (address) {
        address gnosisProxyFactory = addressProvider.gnosisProxyFactory();
        address gnosisSafeSingleton = addressProvider.gnosisSafeSingleton();

        address safe = IGnosisProxyFactory(gnosisProxyFactory).createProxyWithNonce(
            gnosisSafeSingleton, bytes(""), _genNonce(_owner)
        );
        return safe;
    }

    /**
     * @notice Internal function to setup a Safe as a console account.
     * @param safe The address of the Gnosis Safe.
     * @param _owner The address of the Safe owner.
     * @param _feeToken The address of the fee token.
     */
    function _setupSafeAsConsoleAccount(address safe, address _owner, address _feeToken) internal {
        address[] memory owners = new address[](1);
        owners[0] = (_owner);

        Types.Executable[] memory txns = new Types.Executable[](2);

        // Enable BrahRouter as safe module on Console Account
        txns[0] = Types.Executable({
            callType: Types.CallType.CALL,
            target: address(safe),
            value: 0,
            data: abi.encodeCall(IGnosisSafe.enableModule, (addressProvider.brahRouter()))
        });

        // Register console account with WalletRegistry
        txns[1] = Types.Executable({
            callType: Types.CallType.CALL,
            target: walletRegistry,
            value: 0,
            data: abi.encodeCall(
                WalletRegistry.registerWallet,
                (
                    1, // Safe Wallet Adapter ID
                    _feeToken // Fee token
                )
                )
        });

        // Setup safe with single threshold and multi-send
        IGnosisSafe(safe).setup(
            owners,
            1,
            addressProvider.gnosisMultiSend(),
            abi.encodeCall(IGnosisMultiSend.multiSend, (SafeHelper._packMultisendTxns(txns))),
            addressProvider.gnosisFallbackHandler(),
            address(0),
            0,
            address(0)
        );
    }

    /**
     * @notice Internal function to setup a Safe as a sub account.
     * @param safe The address of the Gnosis Safe.
     * @param _wallet The address of the Safe owner.
     */
    function _setupSafeAsSubAccount(address safe, address _wallet) internal {
        address[] memory owners = new address[](1);
        owners[0] = (_wallet);

        Types.Executable[] memory txns = new Types.Executable[](1);
        txns[0] = Types.Executable({
            callType: Types.CallType.CALL,
            target: address(safe),
            value: 0,
            data: abi.encodeCall(IGnosisSafe.enableModule, (_wallet))
        });

        // Cheaper to execute single txn via multisend rather than execTransaction
        IGnosisSafe(safe).setup(
            owners,
            1,
            addressProvider.gnosisMultiSend(),
            abi.encodeCall(IGnosisMultiSend.multiSend, (SafeHelper._packMultisendTxns(txns))),
            addressProvider.gnosisFallbackHandler(),
            address(0),
            0,
            address(0)
        );
    }

    /**
     * @notice Internal function to setup a Safe as a reserve sub account.
     *
     * @dev Setups a safe as a reserve sub account
     *  A reserve sub account is owned by the Safe Deployer
     *
     * @param safe The address of the Gnosis Safe.
     */
    function _setupSafeAsReserveSubAccount(address safe) internal {
        address[] memory owners = new address[](1);

        // Reserve sub accounts are owned by the Safe Deployer
        owners[0] = (address(this));

        IGnosisSafe(safe).setup(
            owners, 1, address(0), bytes(""), addressProvider.gnosisFallbackHandler(), address(0), 0, address(0)
        );
    }

    /**
     * @notice Internal function to get the nonce of a user's safe deployment
     * @param _user address of owner of the safe.
     * @return The nonce of the user's safe deployment.
     */
    function _genNonce(address _user) internal returns (uint256) {
        uint96 currentNonce = ownerSafeCount[_user]++;
        return uint256(keccak256(abi.encodePacked(_user, currentNonce, VERSION)));
    }

    function _onlySubAccountRegistry() internal view {
        if (msg.sender != subAccountRegistry) revert OnlySubAccountRegistry();
    }
}

/**
 * @title SubAccountRegistry
 * @notice SubAccountRegistry is a contract for managing sub-accounts for user wallets.
 */
contract SubAccountRegistry is AddressProviderService {
    error OnlySubscriptionRegistryCallable();
    error SubAccountInActive();

    /// @notice Emitted when a new sub-account is allocated for a wallet.
    event SubAccountAllocated(address indexed wallet, address indexed subAccount);

    mapping(address wallet => address[] subAccountList) public walletToSubAccountMap;
    mapping(address subAccount => address wallet) public subAccountToWalletMap;
    mapping(address subAccount => bool inUse) public subAccountStatus;

    /**
     * @notice Initializes the SubAccountRegistry with the address of AddressProvider.
     * @param _addressProvider The address of AddressProvider.
     */
    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    /**
     * @notice Requests a sub-account for the given wallet.
     *
     * @dev SubscriptionRegistry MUST call this method to allocate a
     *  new subAccount during creation of a new subscription.
     *  This method will return an existing sub-account if one is available.
     *  In case all sub-accounts are in use, a new sub-account
     *  will be requested from SafeDeployer
     *
     * @param _wallet The address of the wallet requesting a sub-account.
     * @return The address of the allocated sub-account.
     */
    function requestSubAccount(address _wallet) external returns (address) {
        if (msg.sender != subscriptionRegistry) revert OnlySubscriptionRegistryCallable();
        // Try to find a subAccount which already exists
        address[] storage subAccountList = walletToSubAccountMap[_wallet];

        uint256 subAccountLen = subAccountList.length;
        if (subAccountLen > 0) {
            uint256 idx = 0;
            do {
                address account = subAccountList[idx];
                if (!subAccountStatus[account]) {
                    subAccountStatus[account] = true;
                    return account;
                }
                unchecked {
                    ++idx;
                }
            } while (idx < subAccountLen);
        }

        // No free subAccount found, get a new one from the SafeDeployer
        address subAccount = SafeDeployer(addressProvider.safeDeployer()).allocateOrDeployFreshSubAccount(_wallet);

        emit SubAccountAllocated(_wallet, subAccount);
        // Register it
        subAccountToWalletMap[subAccount] = _wallet;
        subAccountList.push(subAccount);
        subAccountStatus[subAccount] = true;

        return subAccount;
    }

    /**
     * @notice Relinquishes a sub-account back to the registry.
     *
     * @dev SubscriptionRegistry MUST call this method to relinquish
     *  the subAccount used while cancelling a subscription.
     *  This will mark the subAccount as inactive. It will not revoke
     *  ownership of the subAccount from the wallet.
     *  The subAccount will be available for re-allocation
     *  when subscription registry requests for a new subAccount for the wallet.
     *
     * @param _subAccount The address of the sub-account to be relinquished.
     */
    function relinquishSubAccount(address _subAccount) external {
        if (msg.sender != subscriptionRegistry) revert OnlySubscriptionRegistryCallable();
        if (!subAccountStatus[_subAccount]) revert SubAccountInActive();
        subAccountStatus[_subAccount] = false;
    }

    /**
     * @notice Fetches all sub-accounts associated with a wallet.
     * @param _wallet The address of the wallet.
     * @return An array of addresses of all sub-accounts associated with the wallet.
     */
    function fetchAllSubAccounts(address _wallet) external view returns (address[] memory) {
        return walletToSubAccountMap[_wallet];
    }
}

/**
 * @notice SubscriptionRegistry is a contract for managing subscriptions to strategies.
 */
contract SubscriptionRegistry is AddressProviderService {
    error SubNotActive();
    error TaskNotFound();
    error OnlyStrategy(address);
    error NotSubAccountOwner(address);
    error StrategyUnsupported();
    error StrategyIsSupported();
    error WalletNotRegistered();
    error EmergencyPaused();

    event SubscriptionCreated(
        address indexed wallet, address indexed strategy, address indexed subAccount, bool externalTask
    );
    event SubscriptionCancelled(address indexed wallet, address indexed strategy, address indexed subAccount);
    event SubAccountRescued(address indexed subAccount, address indexed wallet);

    struct TaskData {
        bytes32 automationId;
        bytes32 keeperTaskId;
    }

    struct Subscription {
        bool active;
        bool trusted;
        bytes subData;
        bytes tasks;
    }

    mapping(address subAccount => address strategy) public subAccountMap;
    mapping(bytes32 subAccountStrategyHash => Subscription subscription) public subRegistry;

    /**
     * @notice Initializes the SubscriptionRegistry with the address of AddressProvider.
     * @param _addressProvider The address of AddressProvider.
     */
    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    /**
     * @notice Creates a subscription for the given wallet and strategy.
     *
     *  A user can create multiple subscriptions to the same strategy.
     *  Each subscription will have its own sub-account.
     *
     * @dev The subscription flow consists of the following steps:
     *      1. Request a new sub-account from SubAccountRegistry.
     *      2. Create tasks for the given automations.
     *      3. Create a new subscription with task details and subscription data.
     *      4. Request funds for the sub-account from user wallet.
     *
     * @param _externalTask A boolean indicating if tasks should be created on external keeper networks.
     * @param _trusted A boolean indicating if the subscription is trusted.
     * @param _wallet The address of the wallet.
     * @param _strategy The address of the strategy.
     * @param _subData Subscription data.
     * @param _automationIds An array of automation IDs.
     * @param _tokenRequests An array of TokenRequests.
     * @return The address of the created sub-account.
     */
    function createSubscription(
        bool _externalTask,
        bool _trusted,
        address _wallet,
        address _strategy,
        bytes memory _subData,
        bytes32[] memory _automationIds,
        Types.TokenRequest[] memory _tokenRequests
    ) external returns (address) {
        if (BrahRouter(addressProvider.brahRouter()).isEmergencyPaused()) revert EmergencyPaused();

        _onlyStrategy(_strategy);

        if (!WalletRegistry(walletRegistry).isWallet(_wallet)) revert WalletNotRegistered();

        address subAccount = SubAccountRegistry(subAccountRegistry).requestSubAccount(_wallet);

        uint256 automationsLen = _automationIds.length;
        TaskData[] memory tasks = new TaskData[](automationsLen);

        if (automationsLen > 0) {
            uint256 idx = 0;
            do {
                bytes32 _keeperTaskId = BotManager(addressProvider.botManager()).createTask(
                    _externalTask, _strategy, _wallet, subAccount, _automationIds[idx]
                );

                tasks[idx] = TaskData({automationId: _automationIds[idx], keeperTaskId: _keeperTaskId});
                unchecked {
                    ++idx;
                }
            } while (idx < automationsLen);
        }

        Subscription memory newSub =
            Subscription({active: true, trusted: _trusted, subData: _subData, tasks: abi.encode(tasks)});

        subAccountMap[subAccount] = _strategy;
        subRegistry[subAccountStrategyHash(subAccount, _strategy)] = newSub;

        BrahRouter(addressProvider.brahRouter()).requestSubAccountFunds(_wallet, subAccount, _tokenRequests);

        emit SubscriptionCreated(_wallet, _strategy, subAccount, _externalTask);

        return subAccount;
    }

    /**
     * @notice Checks if the automation is active for a given strategy and sub-account.
     *
     * @param _strategy The address of the strategy.
     * @param _automationId The automation ID.
     * @param _subAccount The address of the sub-account.
     * @return A boolean indicating if the automation is active.
     */
    function isAutomationActive(address _strategy, bytes32 _automationId, address _subAccount)
        external
        view
        returns (bool)
    {
        if (subAccountMap[_subAccount] != _strategy) return false;
        if (!subRegistry[subAccountStrategyHash(_subAccount, _strategy)].active) return false;
        TaskData[] memory tasks =
            abi.decode(subRegistry[subAccountStrategyHash(_subAccount, _strategy)].tasks, (TaskData[]));

        uint256 taskLen = tasks.length;

        if (taskLen > 0) {
            uint256 idx = 0;
            do {
                if (tasks[idx].automationId == _automationId) return true;
                unchecked {
                    ++idx;
                }
            } while (idx < taskLen);
        }

        return false;
    }

    /**
     * @notice Updates the subscription data for a given sub-account and strategy.
     * @param _subAccount The address of the sub-account.
     * @param _strategy The address of the strategy.
     * @param _subData The updated subscription data.
     */
    function updateSubData(address _subAccount, address _strategy, bytes calldata _subData) external {
        _onlyStrategy(_strategy);
        if (!isStrategyActive(_subAccount, _strategy)) revert SubNotActive();

        subRegistry[subAccountStrategyHash(_subAccount, _strategy)].subData = _subData;
    }

    /**
     * @notice Retrieves the subscription data for a given sub-account and strategy.
     * @param _subAccount The address of the sub-account.
     * @param _strategy The address of the strategy.
     * @return The subscription data.
     */
    function retrieveSubData(address _subAccount, address _strategy) external view returns (bytes memory) {
        if (!isStrategyActive(_subAccount, _strategy)) revert SubNotActive();

        return subRegistry[subAccountStrategyHash(_subAccount, _strategy)].subData;
    }

    /**
     * @notice Checks if the strategy is active for a given sub-account.
     * @param _subAccount The address of the sub-account.
     * @param _strategy The address of the strategy.
     * @return A boolean indicating if the strategy is active.
     */
    function isStrategyActive(address _subAccount, address _strategy) public view returns (bool) {
        return subRegistry[subAccountStrategyHash(_subAccount, _strategy)].active;
    }

    /**
     * @notice Checks if the subscription is trusted for a given sub-account.
     * @param _subAccount The address of the sub-account.
     * @param _strategy The address of the strategy.
     * @return A boolean indicating if the subscription is trusted.
     */
    function isSubscriptionTrusted(address _subAccount, address _strategy) external view returns (bool) {
        return subRegistry[subAccountStrategyHash(_subAccount, _strategy)].trusted;
    }

    /**
     * @notice Cancels a subscription for a given sub-account and strategy.
     *
     *  @dev Before cancelling the subscription, a strategy MUST transfer
     *  all funds from the sub-account to the wallet.
     *  and restore subaccount back to native state
     *  After cancelling the subscription, the strategy
     *  will loose execution privilege on the subAccount
     *
     * @param _subAccount The address of the sub-account.
     * @param _strategy The address of the strategy.
     */
    function cancelSubscription(address _subAccount, address _strategy) external {
        _onlyStrategy(_strategy);
        if (subAccountMap[_subAccount] != _strategy) revert SubNotActive();
        if (!isStrategyActive(_subAccount, _strategy)) revert SubNotActive();
        address _wallet = SubAccountRegistry(subAccountRegistry).subAccountToWalletMap(_subAccount);
        _removeSubscriptionAndFreeUpSubAccount(_subAccount, _strategy, _wallet);
    }

    /**
     * @notice Allows owner to rescue a sub-account.
     *
     *  @dev Can be called when a strategy is no longer supported.
     *  while a subscription is still active
     *  Can only be called by the owner of the sub-account
     *
     * @param _subAccount The address of the sub-account.
     */
    function rescueSubAccount(address _subAccount) external {
        if (SubAccountRegistry(subAccountRegistry).subAccountToWalletMap(_subAccount) != msg.sender) {
            revert NotSubAccountOwner(msg.sender);
        }
        address _strategy = subAccountMap[_subAccount];
        if (!isStrategyActive(_subAccount, _strategy)) revert SubNotActive();
        if (StrategyRegistry(strategyRegistry).isStrategySupported(_strategy)) {
            revert StrategyIsSupported();
        }
        _removeSubscriptionAndFreeUpSubAccount(_subAccount, _strategy, msg.sender);
    }

    /**
     * @dev Fetches all active tasks for subscription
     *  Removes tasks from BotManager
     *  Deletes subscription
     *  Frees up subAccount
     */
    function _removeSubscriptionAndFreeUpSubAccount(address _subAccount, address _strategy, address _owner) internal {
        bytes32 _subAccountStrategyHash = subAccountStrategyHash(_subAccount, _strategy);
        Subscription storage existingSub = subRegistry[_subAccountStrategyHash];
        TaskData[] memory tasks = abi.decode(existingSub.tasks, (TaskData[]));

        delete subRegistry[_subAccountStrategyHash];
        delete subAccountMap[_subAccount];

        uint256 taskLen = tasks.length;
        if (taskLen > 0) {
            uint256 idx = 0;
            do {
                BotManager(addressProvider.botManager()).removeTask(tasks[idx].keeperTaskId);
                unchecked {
                    ++idx;
                }
            } while (idx < taskLen);
        }

        SubAccountRegistry subAccountRegistry = SubAccountRegistry(subAccountRegistry);
        emit SubscriptionCancelled(_owner, _strategy, _subAccount);
        subAccountRegistry.relinquishSubAccount(_subAccount);
    }

    /**
     * @notice Calculates the sub-account strategy hash.
     * @dev This is used to create a unique identifier for a sub-account and strategy.
     * @param _subAccount The address of the sub-account.
     * @param _strategy The address of the strategy.
     * @return The calculated sub-account strategy hash.
     */
    function subAccountStrategyHash(address _subAccount, address _strategy) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_subAccount, _strategy));
    }

    /**
     * @notice Checks if the caller is a registered strategy.
     * @param _strategy The address of the strategy.
     */
    function _onlyStrategy(address _strategy) internal view {
        if (msg.sender != _strategy) revert OnlyStrategy(msg.sender);
        if (!StrategyRegistry(strategyRegistry).isStrategySupported(_strategy)) {
            revert StrategyUnsupported();
        }
    }
}

/**
 * @title Authorizer
 * @notice Contract that implements general authorization logic for bots and strategies
 */
abstract contract Authorizer is AddressProviderService {
    error InvalidPayer(address);
    error StrategyDoesntExist();
    error StrategyUnActive();
    error UnauthorizedBot(address);
    error UnauthorizedKeeper(address);
    error UntrustedSubscription();
    error TrustedSubscription();

    /// @notice internal keeper service
    address public keeper;

    /**
     * @notice Validates that Automation is active and belongs to the wallet and subaccount
     */
    function _validateAutomation(address _wallet, address _subAccount, address _strategy, bytes32 _automationId)
        internal
        view
    {
        // Check that wallet is the owner of the subAccount
        address owner = SubAccountRegistry(subAccountRegistry).subAccountToWalletMap(_subAccount);
        if (owner != _wallet) {
            revert InvalidPayer(_wallet);
        }

        // Check that strategy registered with StrategyRegistry
        if (!StrategyRegistry(strategyRegistry).isStrategySupported(_strategy)) {
            revert StrategyDoesntExist();
        }

        // Check that subscription exists and automation is active
        if (!SubscriptionRegistry(subscriptionRegistry).isAutomationActive(_strategy, _automationId, _subAccount)) {
            revert StrategyUnActive();
        }
    }

    /**
     * @notice Validates that bot is authorized to execute the transaction
     */
    function _validateBot() internal view {
        // Check that bot is registered with BotManager or internal keeper
        if (_isKeeper() || _isBot()) {
            return;
        }
        revert UnauthorizedBot(msg.sender);
    }

    function _validateConsoleKeeper() internal view {
        if (!_isKeeper()) {
            revert UnauthorizedKeeper(msg.sender);
        }
    }

    function _isKeeper() internal view returns (bool) {
        return msg.sender == keeper;
    }

    function _isBot() internal view returns (bool) {
        return msg.sender == addressProvider.botManager();
    }

    /**
     * @notice Validates that subscription is external and strategy is authorized to execute the transaction on subAccount
     */
    function _validateExternalSubscription(address strategy, address subAccount) internal view {
        if (SubscriptionRegistry(subscriptionRegistry).isSubscriptionTrusted(subAccount, strategy)) {
            revert TrustedSubscription();
        }

        _validateStrategy(strategy, subAccount);
    }

    /**
     * @notice Validates that subscription is trusted and strategy is authorized to execute the transaction on subAccount
     */
    function _validateTrustedSubscription(address strategy, address subAccount) internal view {
        if (!SubscriptionRegistry(subscriptionRegistry).isSubscriptionTrusted(subAccount, strategy)) {
            revert UntrustedSubscription();
        }

        _validateStrategy(strategy, subAccount);
    }

    /**
     * @notice Validates that strategy is authorized to execute the transaction on subAccount
     */
    function _validateStrategy(address strategy, address subAccount) internal view {
        // Check that strategy registered with StrategyRegistry
        if (!StrategyRegistry(strategyRegistry).isStrategySupported(strategy)) {
            revert StrategyDoesntExist();
        }

        // Check that strategy is active on subAccount
        if (!SubscriptionRegistry(subscriptionRegistry).isStrategyActive(subAccount, strategy)) {
            revert StrategyUnActive();
        }
    }
}

/**
 * @title Executor
 * @notice This abstract contract is responsible for executing Types.Executables on subaccounts and main safe.
 * @dev Inherited by BrahRouter and provides utility functions for executing transactions on wallets and subaccounts.
 *  Executor cannot inherit AddressProviderService as it is inherited by BrahRouter
 */

abstract contract Executor is AddressProviderService {
    error UnsupportedExecution(uint8);
    error NonStaticExecution(uint8);
    error UnsupportedWallet(address);
    error StrategyBlocked();
    error InvalidTriggers();
    error InvalidTarget();
    error InvalidActions();
    error InvalidTxnValue(uint256);
    error NotGuardianOrGovernance(address);
    error EmergencyPaused();
    error WalletCallFailed(bytes);
    error SubAccountCallFailed(bytes);
    error BrahRouterCallFailed(bytes);

    bool public isEmergencyPaused;

    /**
     * @notice Sets the emergency pause state.
     * @dev Guardian or Governance can set the emergency pause state to true.
     *  Only Governance can set the emergency pause state to false.
     * @param _isEmergencyPaused The boolean value to set the emergency pause state to.
     */
    function setEmergencyPause(bool _isEmergencyPaused) external {
        address governance = addressProvider.governance();
        if (_isEmergencyPaused) {
            if (msg.sender == governance || msg.sender == addressProvider.guardian()) {
                isEmergencyPaused = true;
            } else {
                revert NotGuardianOrGovernance(msg.sender);
            }
        } else {
            if (msg.sender == governance) {
                isEmergencyPaused = false;
            } else {
                revert NotGovernance(msg.sender);
            }
        }
    }

    /**
     * @notice Finds the wallet adapter for a registered wallet.
     * @param _wallet The wallet address for which the adapter is being fetched.
     * @return adapter The IWalletAdapter instance for the given wallet.
     */
    function findWalletAdapter(address _wallet) public view returns (IWalletAdapter adapter) {
        uint8 walletType = WalletRegistry(walletRegistry).walletType(_wallet);
        adapter = IWalletAdapter(WalletAdapterRegistry(walletAdapterRegistry).walletAdapter(walletType));
        if (address(adapter) == address(0)) revert UnsupportedWallet(_wallet);
    }

    /**
     * @notice Executes a static transaction.
     * @param _txn The Types.Executable struct containing the transaction details.
     * @return success A boolean indicating if the execution was successful
     * @return result Return data of static call encoded as bytes
     */
    function _executeStatic(Types.Executable memory _txn) internal view returns (bool success, bytes memory result) {
        if (_txn.callType != Types.CallType.STATICCALL) {
            revert NonStaticExecution(uint8(_txn.callType));
        }
        if (_txn.target == address(0)) {
            revert InvalidTarget();
        }
        (success, result) = (_txn.target).staticcall(_txn.data);
    }

    /**
     * @notice Checks if the trigger should be executed for the given wallet, strategy, and automationId.
     *
     *     A list of triggers is fetched from the strategy contract. These triggers can be custom
     *     executables which can depend on on the subaccount and automation id
     *
     *     All triggers MUST  fulfil following assumptions
     *     - They MUST be static calls
     *     - They MUST return a boolean value
     *     - They MUST return true if the trigger is satisfied
     *     - They can either revert or return false in case trigger is not satisfied
     *     - They MUST NOT depend on any environment context like msg.sender
     *
     * @param _subAccount The wallet address.
     * @param _strategy The strategy contract address.
     * @param _automationId The automation identifier.
     * @return A boolean indicating if the trigger should be executed.
     */
    function _checkTrigger(address _subAccount, address _strategy, bytes32 _automationId)
        internal
        view
        returns (bool)
    {
        IStrategy strategy = IStrategy(_strategy);

        Types.Executable[] memory triggerCheck = strategy.getTriggerExecs(_automationId, _subAccount);

        uint256 triggerLen = triggerCheck.length;

        if (triggerLen == 0) {
            revert InvalidTriggers();
        } else {
            uint256 idx = 0;
            do {
                (bool success, bytes memory result) = _executeStatic(triggerCheck[idx]);
                if (success) {
                    if (!abi.decode(result, (bool))) return false;
                } else {
                    return false;
                }
                unchecked {
                    ++idx;
                }
            } while (idx < triggerLen);
        }

        return true;
    }

    /**
     * @notice Executes an automation for the given wallet, subAccount, strategy, and automationId.
     *
     * @dev This method MUST be called only after `_checkTrigger` has been called and returned true.
     *  This method does not verify if the wallet is the owner of the subAccount.
     *  If the wallet does not have safe module privileges on the subAccount, the transaction will fail.
     *
     *  We also do not confirm wether subaccount has been subscribed to the strategy or not.
     *  As this should have been verified by the Authorizer contract before calling this method.
     *
     * @param _wallet The wallet address.
     * @param _subAccount The subAccount address.
     * @param _strategy The strategy contract address.
     * @param _actionExecs The list of actions to execute.
     */
    function _executeAutomation(
        address _wallet,
        address _subAccount,
        address _strategy,
        Types.Executable[] memory _actionExecs
    ) internal {
        uint256 actionLen = _actionExecs.length;

        if (actionLen == 0) {
            revert InvalidActions();
        } else {
            uint256 idx = 0;
            do {
                _executeOnSubAccount(_wallet, _subAccount, _strategy, _actionExecs[idx]);
                unchecked {
                    ++idx;
                }
            } while (idx < actionLen);
        }
    }

    /**
     * @notice Executes a transaction on a subaccount.
     *
     * @dev It is always assumed that subAccount is a Safe Wallet and will always be compatible with SafeWalletAdapter.
     *  This is enforced by the SubAccountRegistry contract which uses SafeDeployer to deploy new subaccounts.
     *  It is also assumed that SafeWalletAdapter will always have 1 as their ID in the WalletAdapterRegistry contract.
     *
     *  A SubAccount is wholly owned by a wallet (main safe) and can only be executed on by the wallet.
     *  therefore we take the executable to be executed on the subaccount and format it for executing wallet
     *  since wallet is also a safe module on the subaccount, the wallet can call `execTransactionFromModuleReturnData`
     *  on the subaccount.
     *
     * @param _owner The owner address of the subaccount.
     * @param _subAccount The subAccount address.
     * @param strategy The strategy contract address.
     * @param _txn The Types.Executable struct containing the transaction details.
     * @return The returned data from the transaction execution.
     */
    function _executeOnSubAccount(address _owner, address _subAccount, address strategy, Types.Executable memory _txn)
        internal
        returns (bytes memory)
    {
        if (!IStrategy(strategy).isExecutionAllowed(_txn.callType, _txn.target, _subAccount)) revert StrategyBlocked();

        IWalletAdapter adapter = IWalletAdapter(WalletAdapterRegistry(walletAdapterRegistry).walletAdapter(1));
        Types.Executable memory formattedTxn = adapter.formatForWallet(_subAccount, _txn);

        bytes memory result = _executeOnWallet(_owner, formattedTxn);
        (bool txnSuccess, bytes memory txnResult) = adapter.decodeReturnData(result);
        if (!txnSuccess) revert SubAccountCallFailed(txnResult);
        return (txnResult);
    }

    /**
     * @notice Executes a transaction on a wallet (main safe).
     *
     * @dev This method takes a generic transaction as input, transforms it into a transaction
     *  executable by BrahRouter using corresponding wallet adapter and executes it via BrahRouter.
     *  It also checks for successful execution. Since safe does not revert in case of failed transaction,
     *  it checks for success of safe transaction execution by decoding return data and reverts if the transaction fails
     *
     * @param _wallet The wallet address.
     * @param _txn The Types.Executable struct containing the transaction details.
     * @return The returned data from the transaction execution.
     */
    function _executeOnWallet(address _wallet, Types.Executable memory _txn) internal returns (bytes memory) {
        if (isEmergencyPaused) revert EmergencyPaused();

        // Get wallet adapter for the wallet
        IWalletAdapter adapter = findWalletAdapter(_wallet);

        // Format transaction into a BrahRouter compatible executable
        Types.Executable memory formattedTxn = adapter.formatForWallet(_wallet, _txn);

        // Execute transaction
        (bool success, bytes memory result) = _execute(formattedTxn);

        // Check if transaction was successful and return data
        if (!success) revert BrahRouterCallFailed(result);
        (bool txnSuccess, bytes memory txnResult) = adapter.decodeReturnData(result);
        if (!txnSuccess) revert WalletCallFailed(txnResult);
        return (txnResult);
    }

    /**
     *
     * @notice Executes a transaction based on the provided Types.Executable struct.
     *
     * @dev This method is used to execute transaction on a main wallet.
     *  The transaction should be encoded in such a way that it can be executed on the main wallet.
     *  As an example, in case of safe, the transaction is encoded via `execTransactionFromModuleReturnData` method.
     *  This assumes that `BrahRouter` contract has privileges to execute transactions on target which is user's wallet
     *  only supports transactions with callType set to Types.CallType.CALL.
     *
     * @param _txn The Types.Executable struct containing the transaction details.
     * @return success A boolean indicating if the execution was successful
     * @return result The returned data from the transaction execution.
     */
    function _execute(Types.Executable memory _txn) private returns (bool success, bytes memory result) {
        if (_txn.callType == Types.CallType.CALL) {
            if (_txn.value != 0) revert InvalidTxnValue(_txn.value);
            if (_txn.target == address(0)) revert InvalidTarget();
            (success, result) = _txn.target.call(_txn.data);
        } else {
            revert UnsupportedExecution(uint8(_txn.callType));
        }
    }
}

/**
 * @title FeePayer
 * @notice This abstract contract is responsible for handling fees in various transactions.
 * @dev Inherited by BrahRouter and provides utility functions for building fee executables.
 */
abstract contract FeePayer is AddressProviderService {
    event FeeMultiplierSet(uint16 feeMultiplier);
    event GasOverheadNativeSet(uint32 gasOverheadNative);
    event GasOverheadERC20Set(uint32 gasOverheadERC20);

    error OnlyGovernance();
    error InvalidFeeMultiplier(uint16);

    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // BASE_BPS represents 100%
    uint16 internal constant BASE_BPS = 10_000;

    // MAX_MULTIPLIER represents 140%
    uint16 internal constant MAX_MULTIPLIER = 14_000;

    /**
     * @notice feeMultiplier represents the total fee to be charged on the transaction
     *  Is set to 100% by default
     * @dev In case feeMultiplier is less than BASE_BPS, fees charged will be less than 100%,
     *  subsidizing the transaction
     *  In case feeMultiplier is greater than BASE_BPS, fees charged will be greater than 100%,
     *  charging the user for the transaction
     */
    uint16 public feeMultiplier = 10_000;

    /**
     * Keeper network overhead - 150k
     * Contains gas overhead for computing, executing fee transfer, verifying fee transfer
     * and emitting fee claim event
     */
    uint32 public gasOverheadNative = 150_000 + 50_000;
    uint32 public gasOverheadERC20 = 150_000 + 100_000;

    /**
     * @notice Sets the fee multiplier for the automated executions
     * @dev Should not be able to set fee multiplier greater than 140%
     */
    function setFeeMultiplier(uint16 _feeMultiplier) external {
        if (_feeMultiplier > MAX_MULTIPLIER) revert InvalidFeeMultiplier(_feeMultiplier);
        _onlyGov();
        feeMultiplier = _feeMultiplier;
    }

    /**
     * @notice Sets the gas overhead for the automated executions when fee token is ETH
     * @dev Only callable by governance
     */
    function setGasOverheadNative(uint32 _gasOverheadNative) external {
        _onlyGov();
        gasOverheadNative = _gasOverheadNative;
        emit GasOverheadNativeSet(_gasOverheadNative);
    }

    /**
     * @notice Sets the gas overhead for the automated executions when fee token is ERC20
     * @dev Only callable by governance
     */
    function setGasOverheadERC20(uint32 _gasOverheadERC20) external {
        _onlyGov();
        gasOverheadERC20 = _gasOverheadERC20;
        emit GasOverheadERC20Set(_gasOverheadERC20);
    }

    /**
     * @notice Returns the fee token associated with the given wallet.
     * @param wallet The wallet address for which the fee token is being fetched.
     * @return address of the fee token.
     */
    function _feeToken(address wallet) internal view returns (address) {
        return WalletRegistry(walletRegistry).walletFeeToken(wallet);
    }

    /**
     * @notice Builds a fee executable based on the gas used and the fee token.
     * @param gasUsed The amount of gas used in the transaction.
     * @param feeToken The address of the fee token.
     * @param recipient The address of the recipient of the fee.
     * @return uint256 The total fee amount.
     * @return Types.Executable struct containing the fee execution details.
     */
    function _buildFeeExecutable(uint256 gasUsed, address feeToken, address recipient)
        internal
        view
        returns (uint256, Types.Executable memory)
    {
        if (feeToken == ETH) {
            uint256 totalFee = (gasUsed + gasOverheadNative) * tx.gasprice;
            totalFee = _applyMultiplier(totalFee);
            return (totalFee, TokenTransfer._nativeTransferExec(recipient, totalFee));
        } else {
            uint256 totalFee = (gasUsed + gasOverheadERC20) * tx.gasprice;
            // Convert fee amount value in fee token
            uint256 feeToCollect =
                PriceFeedManager(addressProvider.priceFeedManager()).getTokenXPriceInY(totalFee, ETH, feeToken);
            feeToCollect = _applyMultiplier(feeToCollect);
            return (feeToCollect, TokenTransfer._erc20TransferExec(feeToken, recipient, feeToCollect));
        }
    }

    /**
     * @notice Applies the fee multiplier to the given fee amount
     */
    function _applyMultiplier(uint256 fee) internal view returns (uint256) {
        return (fee * uint256(feeMultiplier)) / uint256(BASE_BPS);
    }
}

/**
 * @title BrahRouter
 * @notice BrahRouter is the contract that acts as safe module and executor for strategies on subAccounts
 */
contract BrahRouter is ReentrancyGuard, AddressProviderService, Authorizer, Executor,  FeePayer {
    /**
     * @notice event emitted when strategy executes code on subAccount
     * @param subAccount address of subAccount
     * @param strategy address of strategy
     * @param callData bytes callData of the function to be executed
     */
    event StrategicExecution(address indexed subAccount, address indexed strategy, bytes callData);

    /**
     * @notice event emitted when bot executes code on subAccount
     * @param subAccount address of subAccount
     * @param strategy address of strategy
     * @param automationId ID of automation to execute
     */
    event BotExecution(address indexed subAccount, address indexed strategy, bytes32 indexed automationId);

    /**
     * @notice event emitted when bot executes code on subAccount
     * @param subAccount address of subAccount
     * @param strategy address of strategy
     */
    event TrustedExecution(address indexed subAccount, address indexed strategy);

    /**
     * @notice event emitted when fees are claimed
     * @param wallet address of wallet
     * @param token address of token
     * @param amount amount of token claimed
     */
    event FeeClaimed(address indexed wallet, address indexed token, uint256 amount);

    error TriggerFailed();
    error InvalidKeeper();
    error OnlySubscriptionRegistry();
    error ExceededGasBudget();
    error ReentrancyDetected();
    error UnsuccessfulERC20Transfer(address wallet, address token);
    error UnsuccessfulFeeTransfer(address wallet, address token);

    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    /**
     * @notice Method called by strategy to execute transaction on subAccount
     * @dev Will only be called when the strategy is active on the subAccount
     * @param _subAccount address of subAccount
     * @param _txn Executable transaction to be executed
     * @return bytes result of the transaction
     */
    function strategicExecute(address _subAccount, Types.Executable calldata _txn) external returns (bytes memory) {
        Authorizer._validateStrategy(msg.sender, _subAccount);
        address owner = SubAccountRegistry(subAccountRegistry).subAccountToWalletMap(_subAccount);
        bytes memory txnResult = Executor._executeOnSubAccount(owner, _subAccount, msg.sender, _txn);

        emit StrategicExecution(_subAccount, msg.sender, _txn.data);
        return txnResult;
    }

    /**
     * @notice Method called by keeper to validate automation and fetch action executable
     * @param _wallet address of wallet
     * @param _subAccount address of subAccount
     * @param _strategy address of strategy
     * @param _automationId ID of automation to execute
     * @return actionExecs array of actionExecutables to be executed
     */
    function getAutomation(address _wallet, address _subAccount, address _strategy, bytes32 _automationId)
        public
        view
        returns (Types.Executable[] memory)
    {
        if (!canExecute(_wallet, _subAccount, _strategy, _automationId)) {
            revert TriggerFailed();
        }

        return (IStrategy(_strategy).getActionExecs(_automationId, _subAccount));
    }

    /**
     * @notice Method called by trusted console keeper to execute automation on subAccount
     * @dev Will only be called when the strategy is active on the subAccount
     *  Will also try to charge fees for execution on wallet
     * @param _wallet address of wallet
     * @param _subAccount address of subAccount
     * @param _strategy address of strategy
     * @param _actionExecs array of actionExecutables to be executed
     */
    function executeTrustedAutomation(
        address _wallet,
        address _subAccount,
        address _strategy,
        Types.Executable[] calldata _actionExecs
    ) external nonReentrant claimExecutionFees(_wallet) {
        Authorizer._validateConsoleKeeper();
        Authorizer._validateTrustedSubscription(_strategy, _subAccount);
        Executor._executeAutomation(_wallet, _subAccount, _strategy, _actionExecs);

        emit TrustedExecution(_subAccount, _strategy);
    }

    /**
     * @notice Method called by keeper services to execute automation on subAccount
     * @dev Will only be called when the strategy is active on the subAccount
     *  Will also try to charge fees for execution on wallet
     * @param _wallet address of wallet
     * @param _subAccount address of subAccount
     * @param _strategy address of strategy
     * @param automationId ID of automation to execute
     */
    function executeAutomationViaBot(address _wallet, address _subAccount, address _strategy, bytes32 automationId)
        external
        nonReentrant
        claimExecutionFees(_wallet)
    {
        Authorizer._validateBot();
        Authorizer._validateExternalSubscription(_strategy, _subAccount);
        Executor._executeAutomation(
            _wallet, _subAccount, _strategy, getAutomation(_wallet, _subAccount, _strategy, automationId)
        );

        emit BotExecution(_subAccount, _strategy, automationId);
    }

    /**
     * @notice View method to check if automation can be executed
     * @param _wallet address of wallet
     * @param _subAccount address of subAccount
     * @param _strategy address of strategy
     * @param automationId ID of automation to execute
     * @return bool true if automation can be executed
     */
    function canExecute(address _wallet, address _subAccount, address _strategy, bytes32 automationId)
        public
        view
        returns (bool)
    {
        Authorizer._validateAutomation(_wallet, _subAccount, _strategy, automationId);
        return Executor._checkTrigger(_subAccount, _strategy, automationId);
    }

    /**
     * @notice Method called by subscriptionRegistry to request funds for subAccount
     * @dev Should only be called during the creation of a strategy subscription
     *  During creation of a subscription, tokenRequests are used to transfer necessary funds
     *  from wallet to subAccount
     * @param _wallet address of wallet
     * @param _subAccount address of subAccount
     * @param _tokenRequests array of TokenRequests to be fulfilled
     */
    function requestSubAccountFunds(address _wallet, address _subAccount, Types.TokenRequest[] calldata _tokenRequests)
        external
    {
        if (msg.sender != subscriptionRegistry) {
            revert OnlySubscriptionRegistry();
        }

        uint256 tokenRequestLen = _tokenRequests.length;

        if (tokenRequestLen > 0) {
            uint256 idx = 0;
            do {
                if (_tokenRequests[idx].amount != 0) {
                    Types.Executable memory tokenTransfer = TokenTransfer._erc20TransferExec(
                        _tokenRequests[idx].token, _subAccount, _tokenRequests[idx].amount
                    );
                    _executeSafeERC20Transfer(_wallet, tokenTransfer);
                }
                unchecked {
                    ++idx;
                }
            } while (idx < tokenRequestLen);
        }
    }

    /**
     * @notice Allows governance to set keeper
     * @param _keeper address of keeper
     */
    function setKeeper(address _keeper) external {
        if (_keeper == address(0)) revert InvalidKeeper();
        _onlyGov();
        keeper = _keeper;
    }

    /**
     * @notice Helper method to execute ERC20 transfer safely
     * @dev Checks return data of ERC20 transfer. In case
     *  data is returned, checks if transfer returned true.
     *  Will revert if ERC20 transfer fails
     * @param wallet address of wallet
     * @param tokenTransferExec Executable transaction to be executed
     */
    function _executeSafeERC20Transfer(address wallet, Types.Executable memory tokenTransferExec) internal {
        bytes memory txnResult = Executor._executeOnWallet(wallet, tokenTransferExec);
        if (txnResult.length > 0) {
            if (!abi.decode(txnResult, (bool))) {
                revert UnsuccessfulERC20Transfer(wallet, tokenTransferExec.target);
            }
        }
    }

    /**
     * @notice Modifier to claim execution fees
     * @dev Will claim execution fees for the wallet
     * @param _wallet address of wallet
     */
    modifier claimExecutionFees(address _wallet) {
        uint256 startGas = gasleft();
        _;
        if (feeMultiplier > 0) {
            address feeToken = FeePayer._feeToken(_wallet);
            address recipient = addressProvider.fundManager();

            if (feeToken != ETH) {
                uint256 initialBalance = IERC20(feeToken).balanceOf(recipient);
                uint256 endGas = gasleft();
                uint256 gasUsed = startGas - endGas;

                (uint256 feeAmount, Types.Executable memory feeTransferTxn) =
                    FeePayer._buildFeeExecutable(gasUsed, feeToken, recipient);

                _executeSafeERC20Transfer(_wallet, feeTransferTxn);

                if (IERC20(feeToken).balanceOf(recipient) - initialBalance < feeAmount) {
                    revert UnsuccessfulFeeTransfer(_wallet, feeToken);
                }

                emit FeeClaimed(_wallet, feeToken, feeAmount);

                if ((endGas - gasleft()) > FeePayer.gasOverheadERC20) {
                    revert ExceededGasBudget();
                }
            } else {
                uint256 initialBalance = recipient.balance;
                uint256 endGas = gasleft();
                uint256 gasUsed = startGas - endGas;

                (uint256 feeAmount, Types.Executable memory feeTransferTxn) =
                    FeePayer._buildFeeExecutable(gasUsed, feeToken, recipient);

                Executor._executeOnWallet(_wallet, feeTransferTxn);

                if (recipient.balance - initialBalance < feeAmount) {
                    revert UnsuccessfulFeeTransfer(_wallet, feeToken);
                }

                emit FeeClaimed(_wallet, feeToken, feeAmount);

                if ((endGas - gasleft()) > FeePayer.gasOverheadNative) {
                    revert ExceededGasBudget();
                }
            }
        }
    }
}

/// @notice Interface to be implemented by bots
interface IBot {
    /// @notice Initialises a task for the bot to execute
    /// @param strategy address of strategy
    /// @param wallet address of wallet
    /// @param subAccount address of sub-account
    /// @param automationId ID of automation
    /// @param internalId internal ID to assign to task
    function initTask(address strategy, address wallet, address subAccount, bytes32 automationId, bytes32 internalId)
        external;

    /// @notice Helper to check if a task is active
    /// @param internalId internal ID of task
    /// @return isTask bool indicating if a task is active
    function isTask(bytes32 internalId) external returns (bool);

    /// @notice get a tasks's actual ID based on internal ID
    /// @param internalId internal ID of task
    /// @return taskId actual task ID
    function getTask(bytes32 internalId) external returns (bytes32);

    /// @notice Removes a registered active task
    /// @param internalId internal ID of task to remove
    function removeTask(bytes32 internalId) external;
}

/**
 * @title BotManager
 * @notice Manages automations/tasks across multiple bots, and provides hooks for bots to execute automations through
 */
contract BotManager is AddressProviderService {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    error BotAlreadyExists();
    error UnauthorizedBot();
    error NoBotFound();
    error OnlySubscriptionRegistry();

    event TaskCreated(
        address indexed strategy,
        address indexed wallet,
        address indexed subAccount,
        bytes32 taskId,
        bytes32 automationId
    );

    event TaskRemoved(bytes32 indexed taskId);

    /// @notice total tasks created
    uint256 private totalTasks;

    /// @notice list of authorized bots that can perform automations
    EnumerableMap.AddressToUintMap authorizedBots;

    constructor(address _addressProvider) AddressProviderService(_addressProvider) {}

    /**
     * @notice Governance function to authorize a bot
     * @param _bot address of bot
     */
    function addBot(address _bot) external {
        _onlyGov();
        // EnumerableMap should return false if the bot already exists
        if (!authorizedBots.set(_bot, authorizedBots.length())) revert BotAlreadyExists();
    }

    /**
     * @notice Governance function to de-authorize a bot
     *
     * @dev Removing a bot does not automatically delete the tasks created by the bot
     *  Any existing tasks on the bot will be rendered invalid
     *  In case the same bot is added after removal, the tasks existent on the bot will be
     *  valid once again, given that subscriptions to said tasks still exist
     *
     * @param _bot address of bot
     */
    function removeBot(address _bot) external {
        _onlyGov();

        // EnumerableMap should return false if the bot does not exist
        if (!authorizedBots.remove(_bot)) revert UnauthorizedBot();
    }

    /**
     * @notice Helper to check if a bot is authorized
     * @param _bot address of bot
     */
    function isAuthorizedBot(address _bot) public view returns (bool) {
        return authorizedBots.contains(_bot);
    }

    /**
     * @notice Creates a task across all authorized bots for automations
     *
     *  @dev Should create a task on all 3rd party bots
     *  Should also emit and event for internal keeper to pick up
     *
     * @param externalTask bool indicating if task should be created on external bots
     * @param strategy address of strategy
     * @param wallet address of wallet
     * @param subAccount address of sub-account
     * @param automationId ID of automation to be executed
     * @return currentTask internal ID of current created task
     */
    function createTask(bool externalTask, address strategy, address wallet, address subAccount, bytes32 automationId)
        external
        returns (bytes32 currentTask)
    {
        _onlySubscriptionRegistry();

        currentTask = bytes32(++totalTasks);

        if (externalTask) {
            uint256 len = authorizedBots.length();
            if (len > 0) {
                uint256 idx = 0;
                do {
                    (address _bot,) = authorizedBots.at(idx);
                    IBot(_bot).initTask(strategy, wallet, subAccount, automationId, currentTask);
                    unchecked {
                        ++idx;
                    }
                } while (idx < len);
            } else {
                revert NoBotFound();
            }
        }

        emit TaskCreated(strategy, wallet, subAccount, currentTask, automationId);
    }

    /**
     * @notice Removes a previously created task from all authorized bots
     * @param internalId internal ID of task to remove
     */
    function removeTask(bytes32 internalId) external {
        _onlySubscriptionRegistry();

        uint256 len = authorizedBots.length();
        if (len > 0) {
            uint256 idx = 0;
            do {
                (address _bot,) = authorizedBots.at(idx);

                if (IBot(_bot).isTask(internalId)) {
                    IBot(_bot).removeTask(internalId);
                }
                unchecked {
                    ++idx;
                }
            } while (idx < len);
        }

        emit TaskRemoved(internalId);
    }

    /**
     * @notice Hook for bots to check if an automation can be executed
     *
     * @dev Should only return true when automation is valid
     *  For an automation to be valid, it must fulfill following criteria:
     *  - Automation must be active
     *  - Automation must be valid for the strategy
     *  - Automation must be present on subaccount
     *  - All triggers should return true for the automation
     *
     * @param strategy address of strategy
     * @param wallet address of wallet
     * @param subAccount address of sub-account
     * @param automationId ID of automation
     * @return canExecute bool indicating if an automation can be executed
     */

    function resolver(address strategy, address wallet, address subAccount, bytes32 automationId)
        external
        view
        returns (bool)
    {
        return (BrahRouter(addressProvider.brahRouter()).canExecute(wallet, subAccount, strategy, automationId));
    }

    /**
     * @notice Hook for bots to execute an automation
     * @param strategy address of strategy
     * @param wallet address of wallet
     * @param subAccount address of sub-account
     * @param automationId ID of automation
     */
    function execute(address strategy, address wallet, address subAccount, bytes32 automationId) external {
        _onlyAuthorizedBot();

        BrahRouter(addressProvider.brahRouter()).executeAutomationViaBot(wallet, subAccount, strategy, automationId);
    }

    function _onlySubscriptionRegistry() internal view {
        if (msg.sender != subscriptionRegistry) revert OnlySubscriptionRegistry();
    }

    function _onlyAuthorizedBot() internal view {
        if (!isAuthorizedBot(msg.sender)) revert UnauthorizedBot();
    }
}