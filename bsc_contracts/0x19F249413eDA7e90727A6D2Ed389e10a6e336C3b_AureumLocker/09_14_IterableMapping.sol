// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "hardhat/console.sol";

library IterableMapping {
    struct SwapLock {
        address owner;
        uint256 tokenValue;
        uint104 status;
    }
    // Iterable mapping from address to uint;
    struct Map {
        uint256[] keys;
        uint256 size;
        mapping(uint256 => SwapLock) values;
        mapping(uint256 => uint256) indexOf;
        mapping(uint256 => bool) inserted;
    }

    function get(Map storage map, uint256 key)
        public
        view
        returns (SwapLock memory)
    {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (uint256)
    {
        return map.keys[index];
    }

    function getSize(Map storage map) public view returns (uint256) {
        return map.size;
    }

    function set(
        Map storage map,
        uint256 key_,
        SwapLock memory swapLock_
    ) public {
        require(!map.inserted[key_], "Id already inserted");
        map.inserted[key_] = true;
        map.values[key_] = swapLock_;
        map.indexOf[key_] = map.keys.length;
        map.keys.push(key_);
        map.size = map.size + 1;
    }

    function remove(Map storage map, uint256 key_) public {
        if (!map.inserted[key_]) {
            return;
        }
        map.size = map.size - 1;
        delete map.inserted[key_];
        delete map.values[key_];

        uint256 index = map.indexOf[key_];
        uint256 lastIndex = map.keys.length - 1;
        uint256 lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key_];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}