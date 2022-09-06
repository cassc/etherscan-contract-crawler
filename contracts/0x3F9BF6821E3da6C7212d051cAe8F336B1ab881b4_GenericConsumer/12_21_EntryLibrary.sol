// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

enum RequestType {
    ORACLE, // build and send a Chainlink request (dataVersion = ORACLE_ARGS_VERSION)
    OPERATOR // build and send an Operator request (dataVersion = OPERATOR_ARGS_VERSION)
}

struct Entry {
    bytes32 specId; // 32 bytes -> slot0
    address oracle; // 20 bytes -> slot1
    uint96 payment; // 12 bytes -> slot1
    address callbackAddr; // 20 bytes -> slot2
    uint96 startAt; // 12 bytes -> slot2
    uint96 interval; // 12 bytes -> slot3
    bytes4 callbackFunctionSignature; // 4 bytes -> slot3
    bool inactive; // 1 byte -> slot3
    RequestType requestType; // 1 byte -> slot3
    bytes buffer;
}

library EntryLibrary {
    error EntryLibrary__EntryIsNotInserted(bytes32 key);

    struct Map {
        bytes32[] keys;
        mapping(bytes32 => Entry) keyToEntry;
        mapping(bytes32 => uint256) indexOf;
        mapping(bytes32 => bool) inserted;
    }

    function getEntry(Map storage _self, bytes32 _key) internal view returns (Entry memory) {
        return _self.keyToEntry[_key];
    }

    function getKeyAtIndex(Map storage _self, uint256 _index) internal view returns (bytes32) {
        return _self.keys[_index];
    }

    function isInserted(Map storage _self, bytes32 _key) internal view returns (bool) {
        return _self.inserted[_key];
    }

    function size(Map storage _self) internal view returns (uint256) {
        return _self.keys.length;
    }

    function remove(Map storage _self, bytes32 _key) internal {
        if (!_self.inserted[_key]) {
            revert EntryLibrary__EntryIsNotInserted(_key);
        }

        delete _self.inserted[_key];
        delete _self.keyToEntry[_key];

        uint256 index = _self.indexOf[_key];
        uint256 lastIndex = _self.keys.length - 1;
        bytes32 lastKey = _self.keys[lastIndex];

        _self.indexOf[lastKey] = index;
        delete _self.indexOf[_key];

        _self.keys[index] = lastKey;
        _self.keys.pop();
    }

    function removeAll(Map storage _self) internal {
        uint256 mapSize = size(_self);
        for (uint256 i = 0; i < mapSize; ) {
            bytes32 key = getKeyAtIndex(_self, 0);
            remove(_self, key);
            unchecked {
                ++i;
            }
        }
    }

    function set(
        Map storage _self,
        bytes32 _key,
        Entry calldata _entry
    ) internal {
        if (!_self.inserted[_key]) {
            _self.inserted[_key] = true;
            _self.indexOf[_key] = _self.keys.length;
            _self.keys.push(_key);
        }
        _self.keyToEntry[_key] = _entry;
    }
}