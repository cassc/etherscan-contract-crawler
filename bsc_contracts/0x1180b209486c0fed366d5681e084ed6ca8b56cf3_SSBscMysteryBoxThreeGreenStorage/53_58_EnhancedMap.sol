// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SlotData.sol";

//this is just a normal mapping, but which holds size and you can specify slot
/*
both key and value shouldn't be 0x00
the key must be unique, the value would be whatever

slot
  key --- value
    a --- 1
    b --- 2
    c --- 3
    c --- 4   X   not allowed
    d --- 3
    e --- 0   X   not allowed
    0 --- 9   X   not allowed

*/
library EnhancedMap {

    using SlotData for bytes32;

    //set value to 0x00 to delete
    function sysEnhancedMapSet(bytes32 slot, bytes32 key, bytes32 value) internal {
        require(key != bytes32(0x00), "sysEnhancedMapSet, notEmptyKey");
        slot.sysMapSet(key, value);
    }

    function sysEnhancedMapAdd(bytes32 slot, bytes32 key, bytes32 value) internal {
        require(key != bytes32(0x00), "sysEnhancedMapAdd, notEmptyKey");
        require(value != bytes32(0x00), "EnhancedMap add, the value shouldn't be empty");
        require(slot.sysMapGet(key) == bytes32(0x00), "EnhancedMap, the key already has value, can't add duplicate key");
        slot.sysMapSet(key, value);
    }

    function sysEnhancedMapDel(bytes32 slot, bytes32 key) internal {
        require(key != bytes32(0x00), "sysEnhancedMapDel, notEmptyKey");
        require(slot.sysMapGet(key) != bytes32(0x00), "sysEnhancedMapDel, the key doesn't has value, can't delete empty key");
        slot.sysMapSet(key, bytes32(0x00));
    }

    function sysEnhancedMapReplace(bytes32 slot, bytes32 key, bytes32 value) internal {
        require(key != bytes32(0x00), "sysEnhancedMapReplace, notEmptyKey");
        require(value != bytes32(0x00), "EnhancedMap replace, the value shouldn't be empty");
        require(slot.sysMapGet(key) != bytes32(0x00), "EnhancedMap, the key doesn't has value, can't replace it");
        slot.sysMapSet(key, value);
    }

    function sysEnhancedMapGet(bytes32 slot, bytes32 key) internal view returns (bytes32){
        require(key != bytes32(0x00), "sysEnhancedMapGet, notEmptyKey");
        return slot.sysMapGet(key);
    }

    function sysEnhancedMapSize(bytes32 slot) internal view returns (uint256){
        return slot.sysMapLen();
    }

}