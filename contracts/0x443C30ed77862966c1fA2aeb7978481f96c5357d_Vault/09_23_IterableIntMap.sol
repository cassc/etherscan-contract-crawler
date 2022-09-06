// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

library IterableIntMap {

    using EnumerableSet for EnumerableSet.AddressSet;

    struct Map {
        // Storage of keys
        EnumerableSet.AddressSet _keys;

        mapping (address => int256) _values;
    }

    /**
    * @dev Adds a key-value pair to a map, or updates the value for an existing
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function _set(Map storage map, address key, int256 value) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
    * @dev plus a key‘s value pair in a map
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function _plus(Map storage map, address key, int256 value) private {
        map._values[key] += value;
        map._keys.add(key);
    }

    /**
    * @dev minus a key‘s value pair in a map
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function _minus(Map storage map, address key, int256 value) private {
        map._values[key] -= value;
        map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, address key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, address key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
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
    function _at(Map storage map, uint256 index) private view returns (address, int256) {
        address key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, address key) private view returns (int256) {
        int256 value = map._values[key];
        return value;
    }

    struct AddressToIntMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(AddressToIntMap storage map, address key, int256 value) internal returns (bool) {
        return _set(map._inner, key, value);
    }

    /**
    * @dev plus a key‘s value pair in a map
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function plus(AddressToIntMap storage map, address key, int256 value) internal {
        return _plus(map._inner, key, value);
    }

    /**
    * @dev minus a key‘s value pair in a map
    * key. O(1).
    *
    * Returns true if the key was added to the map, that is if it was not
    * already present.
    */
    function minus(AddressToIntMap storage map, address key, int256 value) internal {
        return _minus(map._inner, key, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToIntMap storage map, address key) internal returns (bool) {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToIntMap storage map, address key) internal view returns (bool) {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToIntMap storage map) internal view returns (uint256) {
        return _length(map._inner);
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
    function at(AddressToIntMap storage map, uint256 index) internal view returns (address, int256) {
        return _at(map._inner, index);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToIntMap storage map, address key) internal view returns (int256) {
        return _get(map._inner, key);
    }
}