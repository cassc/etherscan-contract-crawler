// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library IterableArrayWithoutDuplicateKeys {
    struct Map {
        address[] keys;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function add(Map storage map, address key) public {
        if (map.inserted[key]) {
            return;
        }
        map.inserted[key] = true;
        map.indexOf[key] = map.keys.length;
        map.keys.push(key);
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}