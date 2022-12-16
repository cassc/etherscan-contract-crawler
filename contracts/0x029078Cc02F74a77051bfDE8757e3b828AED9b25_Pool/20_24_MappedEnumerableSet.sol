// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev EnumerableSet fork to support `address => address[]` mapping
 * @dev Forked from OZ 4.3.2
 */
library MappedEnumerableSet {
    struct Set {
        // Storage of set values
        address[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(address => uint256) _indexes;
    }

    struct AddressSet {
        mapping(address => Set) _ofAddress;
    }

    function _add(
        AddressSet storage set,
        address _key,
        address value
    ) private returns (bool) {
        if (!_contains(set, _key, value)) {
            set._ofAddress[_key]._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._ofAddress[_key]._indexes[value] = set._ofAddress[_key]._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(
        AddressSet storage set,
        address _key,
        address value
    ) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._ofAddress[_key]._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._ofAddress[_key]._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                address lastvalue = set._ofAddress[_key]._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._ofAddress[_key]._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._ofAddress[_key]._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._ofAddress[_key]._values.pop();

            // Delete the index for the deleted slot
            delete set._ofAddress[_key]._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(
        AddressSet storage set,
        address _key,
        address value
    ) private view returns (bool) {
        return set._ofAddress[_key]._indexes[value] != 0;
    }

    function _length(AddressSet storage set, address _key) private view returns (uint256) {
        return set._ofAddress[_key]._values.length;
    }

    function _at(
        AddressSet storage set,
        address _key,
        uint256 index
    ) private view returns (address) {
        return set._ofAddress[_key]._values[index];
    }

    function _values(AddressSet storage set, address _key) private view returns (address[] memory) {
        return set._ofAddress[_key]._values;
    }

    function add(
        AddressSet storage set,
        address key,
        address value
    ) internal returns (bool) {
        return _add(set, key, value);
    }

    function remove(
        AddressSet storage set,
        address key,
        address value
    ) internal returns (bool) {
        return _remove(set, key, value);
    }

    function contains(
        AddressSet storage set,
        address key,
        address value
    ) internal view returns (bool) {
        return _contains(set, key, value);
    }

    function length(AddressSet storage set, address key) internal view returns (uint256) {
        return _length(set, key);
    }

    function at(
        AddressSet storage set,
        address key,
        uint256 index
    ) internal view returns (address) {
        return _at(set, key, index);
    }

    function values(AddressSet storage set, address key) internal view returns (address[] memory) {
        address[] memory store = _values(set, key);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}