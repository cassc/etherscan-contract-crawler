// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SlotData {

    // for map,  key could be 0x00, but value can't be 0x00;
    // if value == 0x00, it mean the key doesn't has any value
    function sysMapSet(bytes32 mappingSlot, bytes32 key, bytes32 value) internal returns (uint256 length){
        length = sysMapLen(mappingSlot);
        bytes32 elementOffset = sysCalcMapOffset(mappingSlot, key);
        bytes32 storedValue = sysLoadSlotData(elementOffset);
        if (value == storedValue) {
            //if value == 0 & storedValue == 0
            //if value == storedValue != 0
            //needn't set same value;
        } else if (value == bytes32(0x00)) {
            //storedValue != 0
            //deleting value
            sysSaveSlotData(elementOffset, value);
            length--;
            sysSaveSlotData(mappingSlot, bytes32(length));
        } else if (storedValue == bytes32(0x00)) {
            //value != 0
            //adding new value
            sysSaveSlotData(elementOffset, value);
            length++;
            sysSaveSlotData(mappingSlot, bytes32(length));
        } else {
            //value != storedValue & value != 0 & storedValue !=0
            //updating
            sysSaveSlotData(elementOffset, value);
        }
        return length;
    }

    function sysMapGet(bytes32 mappingSlot, bytes32 key) internal view returns (bytes32){
        bytes32 elementOffset = sysCalcMapOffset(mappingSlot, key);
        return sysLoadSlotData(elementOffset);
    }

    function sysMapLen(bytes32 mappingSlot) internal view returns (uint256){
        return uint256(sysLoadSlotData(mappingSlot));
    }

    function sysLoadSlotData(bytes32 slot) internal view returns (bytes32){
        //ask a stack position
        bytes32 ret;
        assembly{
            ret := sload(slot)
        }
        return ret;
    }

    function sysSaveSlotData(bytes32 slot, bytes32 data) internal {
        assembly{
            sstore(slot, data)
        }
    }

    function sysCalcMapOffset(bytes32 mappingSlot, bytes32 key) internal pure returns (bytes32){
        return bytes32(keccak256(abi.encodePacked(key, mappingSlot)));
    }

    function calcNewSlot(bytes32 slot, string memory name) internal pure returns (bytes32){
        return keccak256(abi.encodePacked(keccak256(abi.encodePacked(keccak256(abi.encodePacked(slot, name))))));
    }
}