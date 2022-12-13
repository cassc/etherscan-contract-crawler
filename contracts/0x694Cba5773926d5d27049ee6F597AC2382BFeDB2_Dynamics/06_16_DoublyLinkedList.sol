// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import {DoublyLinkedListErrors} from "contracts/libraries/errors/DoublyLinkedListErrors.sol";

struct Node {
    uint32 epoch;
    uint32 next;
    uint32 prev;
    address data;
}

struct DoublyLinkedList {
    uint128 head;
    uint128 tail;
    mapping(uint256 => Node) nodes;
    uint256 totalNodes;
}

library NodeUpdate {
    /***
     * @dev Update a Node previous and next nodes epochs.
     * @param prevEpoch: the previous epoch to link into the node
     * @param nextEpoch: the next epoch to link into the node
     */
    function update(
        Node memory node,
        uint32 prevEpoch,
        uint32 nextEpoch
    ) internal pure returns (Node memory) {
        node.prev = prevEpoch;
        node.next = nextEpoch;
        return node;
    }

    /**
     * @dev Update a Node previous epoch.
     * @param prevEpoch: the previous epoch to link into the node
     */
    function updatePrevious(
        Node memory node,
        uint32 prevEpoch
    ) internal pure returns (Node memory) {
        node.prev = prevEpoch;
        return node;
    }

    /**
     * @dev Update a Node next epoch.
     * @param nextEpoch: the next epoch to link into the node
     */
    function updateNext(Node memory node, uint32 nextEpoch) internal pure returns (Node memory) {
        node.next = nextEpoch;
        return node;
    }
}

library DoublyLinkedListLogic {
    using NodeUpdate for Node;

    /**
     * @dev Insert a new Node in the `epoch` position with `data` address in the data field.
            This function fails if epoch is smaller or equal than the current tail, if
            the data field is the zero address or if a node already exists at `epoch`.
     * @param epoch: The epoch to insert the new node
     * @param data: The data to insert into the new node
     */
    function addNode(DoublyLinkedList storage list, uint32 epoch, address data) internal {
        uint32 head = uint32(list.head);
        uint32 tail = uint32(list.tail);
        // at this moment, we are only appending after the tail. This requirement can be
        // removed in future versions.
        if (epoch <= tail) {
            revert DoublyLinkedListErrors.InvalidNodeId(head, tail, epoch);
        }
        if (exists(list, epoch)) {
            revert DoublyLinkedListErrors.ExistentNodeAtPosition(epoch);
        }
        if (data == address(0)) {
            revert DoublyLinkedListErrors.InvalidData();
        }
        Node memory node = createNode(epoch, data);
        // initialization case
        if (head == 0) {
            list.nodes[epoch] = node;
            setHead(list, epoch);
            // if head is 0, then the tail is also 0 and should be also initialized
            setTail(list, epoch);
            list.totalNodes++;
            return;
        }
        list.nodes[epoch] = node.updatePrevious(tail);
        linkNext(list, tail, epoch);
        setTail(list, epoch);
        list.totalNodes++;
    }

    /***
     * @dev Function to update the Head pointer.
     * @param epoch The epoch value to set as the head pointer
     */
    function setHead(DoublyLinkedList storage list, uint128 epoch) internal {
        if (!exists(list, epoch)) {
            revert DoublyLinkedListErrors.InexistentNodeAtPosition(epoch);
        }
        list.head = epoch;
    }

    /***
     * @dev Function to update the Tail pointer.
     * @param epoch The epoch value to set as the tail pointer
     */
    function setTail(DoublyLinkedList storage list, uint128 epoch) internal {
        if (!exists(list, epoch)) {
            revert DoublyLinkedListErrors.InexistentNodeAtPosition(epoch);
        }
        list.tail = epoch;
    }

    /***
     * @dev Internal function to link an Node to its next node.
     * @param prevEpoch: The node's epoch to link the next epoch.
     * @param nextEpoch: The epoch that will be assigned to the linked node.
     */
    function linkNext(DoublyLinkedList storage list, uint32 prevEpoch, uint32 nextEpoch) internal {
        list.nodes[prevEpoch].next = nextEpoch;
    }

    /***
     * @dev Internal function to link an Node to its previous node.
     * @param nextEpoch: The node's epoch to link the previous epoch.
     * @param prevEpoch: The epoch that will be assigned to the linked node.
     */
    function linkPrevious(
        DoublyLinkedList storage list,
        uint32 nextEpoch,
        uint32 prevEpoch
    ) internal {
        list.nodes[nextEpoch].prev = prevEpoch;
    }

    /**
     * @dev Retrieves the head.
     */
    function getHead(DoublyLinkedList storage list) internal view returns (uint256) {
        return list.head;
    }

    /**
     * @dev Retrieves the tail.
     */
    function getTail(DoublyLinkedList storage list) internal view returns (uint256) {
        return list.tail;
    }

    /**
     * @dev Retrieves the Node denoted by `epoch`.
     * @param epoch: The epoch to get the node.
     */
    function getNode(
        DoublyLinkedList storage list,
        uint256 epoch
    ) internal view returns (Node memory) {
        return list.nodes[epoch];
    }

    /**
     * @dev Retrieves the Node value denoted by `epoch`.
     * @param epoch: The epoch to get the node's value.
     */
    function getValue(
        DoublyLinkedList storage list,
        uint256 epoch
    ) internal view returns (address) {
        return list.nodes[epoch].data;
    }

    /**
     * @dev Retrieves the next epoch of a Node denoted by `epoch`.
     * @param epoch: The epoch to get the next node epoch.
     */
    function getNextEpoch(
        DoublyLinkedList storage list,
        uint256 epoch
    ) internal view returns (uint32) {
        return list.nodes[epoch].next;
    }

    /**
     * @dev Retrieves the previous epoch of a Node denoted by `epoch`.
     * @param epoch: The epoch to get the previous node epoch.
     */
    function getPreviousEpoch(
        DoublyLinkedList storage list,
        uint256 epoch
    ) internal view returns (uint32) {
        return list.nodes[epoch].prev;
    }

    /**
     * @dev Checks if a node is inserted into the list at the specified `epoch`.
     * @param epoch: The epoch to check for existence
     */
    function exists(DoublyLinkedList storage list, uint256 epoch) internal view returns (bool) {
        return list.nodes[epoch].data != address(0);
    }

    /**
     * @dev function to create a new node Object.
     */
    function createNode(uint32 epoch, address data) internal pure returns (Node memory) {
        return Node(epoch, 0, 0, data);
    }
}