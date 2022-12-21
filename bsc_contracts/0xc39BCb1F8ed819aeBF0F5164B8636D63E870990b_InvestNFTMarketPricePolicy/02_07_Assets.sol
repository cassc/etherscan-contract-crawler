// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library Assets {

    using EnumerableSet for EnumerableSet.AddressSet;

    type Key is address;

    enum AssetType {
        NATIVE,
        ERC20
    }

    struct Asset {
        string assetTicker;
        AssetType assetType;
    }

    struct Map {
        EnumerableSet.AddressSet _keys;
        mapping(address => Asset) _values;
    }

    function set(Map storage map, Key key, Asset memory value) internal returns (bool) {
        map._values[Key.unwrap(key)] = value;
        return map._keys.add(Key.unwrap(key));
    }

    function remove(Map storage map, Key key) internal returns (bool) {
        delete map._values[Key.unwrap(key)];
        return map._keys.remove(Key.unwrap(key));
    }

    function contains(Map storage map, Key key) internal view returns (bool) {
        return map._keys.contains(Key.unwrap(key));
    }

    function length(Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    function at(Map storage map, uint256 index) internal view returns (Key, Asset storage) {
        Key key = Key.wrap(map._keys.at(index));
        return (key, map._values[Key.unwrap(key)]);
    }

    function get(Map storage map, Key key) internal view returns (Asset storage) {
        Asset storage value = map._values[Key.unwrap(key)];
        require(contains(map, key), "Assets.Map: nonexistent key");
        return value;
    }

}