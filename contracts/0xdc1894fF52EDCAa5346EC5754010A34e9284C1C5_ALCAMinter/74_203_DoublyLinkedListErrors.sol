// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library DoublyLinkedListErrors {
    error InvalidNodeId(uint256 head, uint256 tail, uint256 id);
    error ExistentNodeAtPosition(uint256 id);
    error InexistentNodeAtPosition(uint256 id);
    error InvalidData();
    error InvalidNodeInsertion(uint256 head, uint256 tail, uint256);
}