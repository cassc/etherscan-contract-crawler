// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/errors/CustomEnumerableMapsErrors.sol";

struct ValidatorData {
    address _address;
    uint256 _tokenID;
}

struct ExitingValidatorData {
    uint128 _tokenID;
    uint128 _freeAfter;
}

struct ValidatorDataMap {
    ValidatorData[] _values;
    mapping(address => uint256) _indexes;
}

library CustomEnumerableMaps {
    /**
     * @dev Add a value to a map. O(1).
     *
     * Returns true if the value was added to the map, that is if it was not
     * already present.
     */
    function add(ValidatorDataMap storage map, ValidatorData memory value) internal returns (bool) {
        if (!contains(map, value._address)) {
            map._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[value._address] = map._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a map using its address. O(1).
     *
     * Returns true if the value was removed from the map, that is if it was
     * present.
     */
    function remove(ValidatorDataMap storage map, address key) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = map._indexes[key];

        if (valueIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = map._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                ValidatorData memory lastValue = map._values[lastIndex];

                // Move the last value to the index where the value to delete is
                map._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                map._indexes[lastValue._address] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved key was stored
            map._values.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(ValidatorDataMap storage map, address key) internal view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of values in the map. O(1).
     */
    function length(ValidatorDataMap storage map) internal view returns (uint256) {
        return map._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(
        ValidatorDataMap storage map,
        uint256 index
    ) internal view returns (ValidatorData memory) {
        return map._values[index];
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     */
    function tryGet(
        ValidatorDataMap storage map,
        address key
    ) internal view returns (bool, ValidatorData memory) {
        uint256 index = map._indexes[key];
        if (index == 0) {
            return (false, ValidatorData(address(0), 0));
        } else {
            return (true, map._values[index - 1]);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(
        ValidatorDataMap storage map,
        address key
    ) internal view returns (ValidatorData memory) {
        (bool success, ValidatorData memory value) = tryGet(map, key);
        if (!success) {
            revert CustomEnumerableMapsErrors.KeyNotInMap(key);
        }
        return value;
    }

    /**
     * @dev Return the entire map in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(ValidatorDataMap storage map) internal view returns (ValidatorData[] memory) {
        return map._values;
    }

    /**
     * @dev Return the address of every entry in the entire map in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the map grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function addressValues(ValidatorDataMap storage map) internal view returns (address[] memory) {
        ValidatorData[] memory _values = values(map);
        address[] memory addresses = new address[](_values.length);
        for (uint256 i = 0; i < _values.length; i++) {
            addresses[i] = _values[i]._address;
        }
        return addresses;
    }
}