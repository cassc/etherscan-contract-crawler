// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SlotData.sol";

//once you input a value, it will auto generate an index for that
//index starts from 1, 0 means this value doesn't exist
//the value must be unique, and can't be 0x00
//the index must be unique, and can't be 0x00
/*

slot
value --- index
    a --- 1
    b --- 2
    c --- 3
    c --- 4   X   not allowed
    d --- 3   X   not allowed
    e --- 0   X   not allowed

indexSlot = keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked(slot))))));
index --- value
    1 --- a
    2 --- b
    3 --- c
    3 --- d   X   not allowed

*/

library EnhancedUniqueIndexMap {

    using SlotData for bytes32;

    // slot : value => index
    function sysUniqueIndexMapAdd(bytes32 slot, bytes32 value) internal {

        require(value != bytes32(0x00));

        bytes32 indexSlot = sysUniqueIndexMapCalcIndexSlot(slot);

        uint256 index = uint256(slot.sysMapGet(value));
        require(index == 0, "sysUniqueIndexMapAdd, value already exist");

        uint256 last = sysUniqueIndexMapSize(slot);
        last ++;
        slot.sysMapSet(value, bytes32(last));
        indexSlot.sysMapSet(bytes32(last), value);
    }

    function sysUniqueIndexMapDel(bytes32 slot, bytes32 value) internal {

        //require(value != bytes32(0x00), "sysUniqueIndexMapDel, value must not be 0x00");

        bytes32 indexSlot = sysUniqueIndexMapCalcIndexSlot(slot);

        uint256 index = uint256(slot.sysMapGet(value));
        require(index != 0, "sysUniqueIndexMapDel, value doesn't exist");

        uint256 lastIndex = sysUniqueIndexMapSize(slot);
        require(lastIndex > 0, "sysUniqueIndexMapDel, lastIndex must be large than 0, this must not happen");
        if (index != lastIndex) {

            bytes32 lastValue = indexSlot.sysMapGet(bytes32(lastIndex));
            //move the last to the current place
            //this would be faster than move all elements forward after the deleting one, but not stable(the sequence will change)
            slot.sysMapSet(lastValue, bytes32(index));
            indexSlot.sysMapSet(bytes32(index), lastValue);
        }
        slot.sysMapSet(value, bytes32(0x00));
        indexSlot.sysMapSet(bytes32(lastIndex), bytes32(0x00));
    }

    function sysUniqueIndexMapDelArrange(bytes32 slot, bytes32 value) internal {

        require(value != bytes32(0x00), "sysUniqueIndexMapDelArrange, value must not be 0x00");

        bytes32 indexSlot = sysUniqueIndexMapCalcIndexSlot(slot);

        uint256 index = uint256(slot.sysMapGet(value));
        require(index != 0, "sysUniqueIndexMapDelArrange, value doesn't exist");

        uint256 lastIndex = (sysUniqueIndexMapSize(slot));
        require(lastIndex > 0, "sysUniqueIndexMapDelArrange, lastIndex must be large than 0, this must not happen");

        slot.sysMapSet(value, bytes32(0x00));

        while (index < lastIndex) {

            bytes32 nextValue = indexSlot.sysMapGet(bytes32(index + 1));
            indexSlot.sysMapSet(bytes32(index), nextValue);
            slot.sysMapSet(nextValue, bytes32(index));

            index ++;
        }

        indexSlot.sysMapSet(bytes32(lastIndex), bytes32(0x00));
    }

    function sysUniqueIndexMapReplace(bytes32 slot, bytes32 oldValue, bytes32 newValue) internal {
        require(oldValue != bytes32(0x00), "sysUniqueIndexMapReplace, oldValue must not be 0x00");
        require(newValue != bytes32(0x00), "sysUniqueIndexMapReplace, newValue must not be 0x00");

        bytes32 indexSlot = sysUniqueIndexMapCalcIndexSlot(slot);

        uint256 index = uint256(slot.sysMapGet(oldValue));
        require(index != 0, "sysUniqueIndexMapDel, oldValue doesn't exists");
        require(uint256(slot.sysMapGet(newValue)) == 0, "sysUniqueIndexMapDel, newValue already exists");

        slot.sysMapSet(oldValue, bytes32(0x00));
        slot.sysMapSet(newValue, bytes32(index));
        indexSlot.sysMapSet(bytes32(index), newValue);
    }

    //============================view & pure============================

    function sysUniqueIndexMapSize(bytes32 slot) internal view returns (uint256){
        return slot.sysMapLen();
    }

    //returns index, 0 mean not exist
    function sysUniqueIndexMapGetIndex(bytes32 slot, bytes32 value) internal view returns (uint256){
        return uint256(slot.sysMapGet(value));
    }

    function sysUniqueIndexMapGetValue(bytes32 slot, uint256 index) internal view returns (bytes32){
        bytes32 indexSlot = sysUniqueIndexMapCalcIndexSlot(slot);
        return indexSlot.sysMapGet(bytes32(index));
    }

    // index => value
    function sysUniqueIndexMapCalcIndexSlot(bytes32 slot) internal pure returns (bytes32){
        return slot.calcNewSlot("index");
    }
}