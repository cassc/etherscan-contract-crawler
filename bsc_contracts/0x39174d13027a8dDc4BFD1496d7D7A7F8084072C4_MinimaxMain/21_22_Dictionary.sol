// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Dictionary {
    struct Entry {
        address key;
        uint value;
    }

    function fromKeys(address[] memory keys) internal pure returns (Entry[] memory) {
        Entry[] memory entries = new Entry[](keys.length);
        for (uint i = 0; i < entries.length; i++) {
            entries[i].key = keys[i];
        }
        return entries;
    }

    function get(Entry[] memory entries, address key) internal pure returns (uint value) {
        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].key == key) {
                return entries[i].value;
            }
        }
        revert("key not found");
    }

    function set(
        Entry[] memory entries,
        address key,
        uint value
    ) internal pure returns (Entry[] memory) {
        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].key == key) {
                entries[i].value = value;
                return entries;
            }
        }

        revert("key not found");
    }
}