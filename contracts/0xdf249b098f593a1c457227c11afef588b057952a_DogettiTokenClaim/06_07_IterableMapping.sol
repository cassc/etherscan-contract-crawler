// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) isClaimed;
    }

    function get(Map storage map, address key) internal view returns (uint256 value, bool isClaimed) {
        value = map.values[key];
        isClaimed = map.isClaimed[key];
    }

    function getIndexOfKey(Map storage map, address key)
        internal
        view
        returns (int256)
    {
        if (map.indexOf[key] == 0) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        internal
        view
        returns (address)
    {
        return map.keys[index];
    }
    function getAllKeys(Map storage map)
        internal
        view
        returns (address[] memory)
    {
        return map.keys;
    }
    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) internal {
        if (map.indexOf[key] > 0) {
            map.values[key] = val;
        } else {
            map.values[key] = val;
            map.keys.push(key);
            map.indexOf[key] = map.keys.length;
        }
    }

    function claim(
        Map storage map,
        address key
    ) internal {
        if (map.indexOf[key] == 0) {
            return;
        }
        map.isClaimed[key] = true;
    }

    function remove(Map storage map, address key) internal {
        if (map.indexOf[key] == 0) {
            return;
        }

        delete map.values[key];
        delete map.isClaimed[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}