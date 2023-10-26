// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import "hardhat/console.sol";

struct ListElement {
    uint data;
    bytes32 pointer;
}

struct SingleLinkedList {
    uint length;
    ListElement head;
    mapping(bytes32 => ListElement) elements;
}

library SingleLinkedListLib {

    error CannotReplaceHead();

    bytes32 constant ZERO_POINTER = keccak256(abi.encode(0));

    function addNode(SingleLinkedList storage self, uint data, uint position) internal {

        if(position == 0 && self.length != 0) revert CannotReplaceHead();
        
        ListElement memory element = ListElement({data: data, pointer: ZERO_POINTER});
        bytes32 elementHash = keccak256(abi.encode(data));

        if(self.length == 0)
        {
            self.head = element;
            self.elements[elementHash] = element;
        }
        else if(position >= self.length)
        {
            // find tail = element with a zero pointer
            ListElement storage toCheck = self.head;
            while(toCheck.pointer != ZERO_POINTER)
            {
                toCheck = self.elements[toCheck.pointer];
            }
            toCheck.pointer = elementHash; /* pointer to new element */
            self.elements[elementHash] = element;
        }
        else
        {
            ListElement storage toCheck = self.head;
            uint iterator;
            while(iterator < position)
            {
                toCheck = self.elements[toCheck.pointer];
                unchecked { iterator = iterator + 1; }
            }
            // after loop executed, iterator is position
            // toCheck is predecessor
            bytes32 oldPointer = toCheck.pointer;
            toCheck.pointer = elementHash;
            element.pointer = oldPointer;
            self.elements[elementHash] = element;
        }
        self.length = self.length + 1;
    }

    function removeNode(SingleLinkedList storage self, uint data) internal {
        // TODO
    }

    function getBeheadedList(SingleLinkedList storage self) internal view returns(uint[] memory) {
        uint toReturnLen = self.length-1;
        uint[] memory beheadedList = new uint[](self.length-1);
        ListElement memory e = self.head;
        for(uint iterator; iterator < toReturnLen;)
        {   
            e = self.elements[e.pointer];
            beheadedList[iterator] = e.data;
            unchecked { iterator = iterator + 1; }
        }
        return beheadedList;
    }

}