// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Plan} from "./Plan.sol";

library Mapping {
    struct Map {
        bytes32[] keys;
        mapping(bytes32 => Plan) values;
        mapping(bytes32 => uint256) indexOf;
        mapping(bytes32 => bool) inserted;
    }

    function set(Map storage map, bytes32 key, Plan memory value) internal {
        require(!map.inserted[key], "Mapping.set: duplicate");

        map.values[key] = value;
        map.indexOf[key] = map.keys.length;
        map.inserted[key] = true;
        map.keys.push(key);
    }

    function remove(Map storage map, bytes32 key) internal {
        require(map.inserted[key], "Mapping.remove: non-existant");

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        bytes32 lastKey = map.keys[map.keys.length - 1];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }

    function exists(Map storage map, bytes32 key) internal view returns (bool) {
        return map.inserted[key];
    }

    function get(
        Map storage map,
        bytes32 key
    ) internal view returns (Plan storage) {
        return map.values[key];
    }

    function all(Map storage map) internal view returns (Plan[] memory) {
        Plan[] memory plans = new Plan[](map.keys.length);

        for (uint256 i = 0; i < map.keys.length; i++)
            plans[i] = map.values[map.keys[i]];

        return plans;
    }
}