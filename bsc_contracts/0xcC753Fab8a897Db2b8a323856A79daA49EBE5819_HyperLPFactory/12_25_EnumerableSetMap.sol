// SPDX-License-Identifier: MIT

/***
 *      ______             _______   __
 *     /      \           |       \ |  \
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *
 *
 *
 */

pragma solidity ^0.8.4;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {
    EnumerableMap
} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

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
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSetMap for EnumerableSetMap.Bytes32ToAddressSetMap;
 *
 *     // Declare a set state variable
 *     EnumerableSetMap.Bytes32ToAddressSetMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `bytes32 -> EnumerableSet.Bytes32Set` (`Bytes32ToAddressSetMap`)
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption,
 *  rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableMap, you can either remove all elements one by one or create
 *  a fresh instance using an array of EnumerableMap.
 * ====
 */
library EnumerableSetMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32SetMap {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => EnumerableSet.Bytes32Set) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key & value was added to the set-map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32SetMap storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._keys.add(key);
        return map._values[key].add(value);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key & value was removed from the set-map, that is if it was present.
     */
    function remove(
        Bytes32ToBytes32SetMap storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        return map._values[key].remove(value);
    }

    /**
     * @dev Returns true if the key & value is in the set-map. O(1).
     */
    function contains(
        Bytes32ToBytes32SetMap storage map,
        bytes32 key,
        bytes32 value
    ) internal view returns (bool) {
        return map._values[key].contains(value);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32SetMap storage map)
        internal
        view
        returns (uint256 result)
    {
        for (uint256 i = 0; i < map._keys.length(); i++) {
            result += length(map, map._keys.at(i));
        }
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32SetMap storage map, bytes32 key)
        internal
        view
        returns (uint256)
    {
        return map._values[key].length();
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
    function at(Bytes32ToBytes32SetMap storage map, uint256 index)
        internal
        view
        returns (bytes32, EnumerableSet.Bytes32Set storage)
    {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32SetMap storage map, bytes32 key)
        internal
        view
        returns (bool, EnumerableSet.Bytes32Set storage)
    {
        EnumerableSet.Bytes32Set storage value = map._values[key];
        return (value.length() != 0, value);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32SetMap storage map, bytes32 key)
        internal
        view
        returns (EnumerableSet.Bytes32Set storage)
    {
        EnumerableSet.Bytes32Set storage value = map._values[key];
        require(value.length() != 0, "EnumerableSetMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32SetMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (EnumerableSet.Bytes32Set storage) {
        EnumerableSet.Bytes32Set storage value = map._values[key];
        require(value.length() != 0, errorMessage);
        return value;
    }

    // Bytes32ToAddressSetMap

    struct Bytes32ToAddressSetMap {
        Bytes32ToBytes32SetMap _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToAddressSetMap storage map,
        bytes32 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(
        Bytes32ToAddressSetMap storage map,
        bytes32 key,
        address value
    ) internal returns (bool) {
        return remove(map._inner, key, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(
        Bytes32ToAddressSetMap storage map,
        bytes32 key,
        address value
    ) internal view returns (bool) {
        return contains(map._inner, key, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToAddressSetMap storage map)
        internal
        view
        returns (uint256)
    {
        return length(map._inner);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToAddressSetMap storage map, bytes32 key)
        internal
        view
        returns (uint256)
    {
        return length(map._inner, key);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToAddressSetMap storage map, uint256 index)
        internal
        view
        returns (bytes32, EnumerableSet.Bytes32Set storage)
    {
        return at(map._inner, index);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(Bytes32ToAddressSetMap storage map, bytes32 key)
        internal
        view
        returns (bool, EnumerableSet.Bytes32Set storage)
    {
        return tryGet(map._inner, key);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToAddressSetMap storage map, bytes32 key)
        internal
        view
        returns (EnumerableSet.Bytes32Set storage)
    {
        return get(map._inner, key);
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToAddressSetMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (EnumerableSet.Bytes32Set storage) {
        return get(map._inner, key, errorMessage);
    }
}