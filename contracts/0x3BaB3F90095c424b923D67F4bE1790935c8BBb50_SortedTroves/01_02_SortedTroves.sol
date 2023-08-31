// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "ITroveManager.sol";

/**
    @title Prisma Sorted Troves
    @notice Based on Liquity's `SortedTroves`:
            https://github.com/liquity/dev/blob/main/packages/contracts/contracts/SortedTroves.sol

            Originally derived from `SortedDoublyLinkedList`:
            https://github.com/livepeer/protocol/blob/master/contracts/libraries/SortedDoublyLL.sol
 */
contract SortedTroves {
    ITroveManager public troveManager;

    Data public data;

    // Information for a node in the list
    struct Node {
        bool exists;
        address nextId; // Id of next node (smaller NICR) in the list
        address prevId; // Id of previous node (larger NICR) in the list
    }

    // Information for the list
    struct Data {
        address head; // Head of the list. Also the node in the list with the largest NICR
        address tail; // Tail of the list. Also the node in the list with the smallest NICR
        uint256 size; // Current size of the list
        mapping(address => Node) nodes; // Track the corresponding ids for each node in the list
    }

    event NodeAdded(address _id, uint256 _NICR);
    event NodeRemoved(address _id);

    function setAddresses(address _troveManagerAddress) external {
        require(address(troveManager) == address(0), "Already set");
        troveManager = ITroveManager(_troveManagerAddress);
    }

    /*
     * @dev Add a node to the list
     * @param _id Node's id
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */

    function insert(address _id, uint256 _NICR, address _prevId, address _nextId) external {
        ITroveManager troveManagerCached = troveManager;

        _requireCallerIsTroveManager(troveManagerCached);

        Node storage node = data.nodes[_id];
        // List must not already contain node
        require(!node.exists, "SortedTroves: List already contains the node");
        // Node id must not be null
        require(_id != address(0), "SortedTroves: Id cannot be zero");

        _insert(node, troveManagerCached, _id, _NICR, _prevId, _nextId);
    }

    function _insert(
        Node storage node,
        ITroveManager _troveManager,
        address _id,
        uint256 _NICR,
        address _prevId,
        address _nextId
    ) internal {
        // NICR must be non-zero
        require(_NICR > 0, "SortedTroves: NICR must be positive");

        address prevId = _prevId;
        address nextId = _nextId;

        if (!_validInsertPosition(_troveManager, _NICR, prevId, nextId)) {
            // Sender's hint was not a valid insert position
            // Use sender's hint to find a valid insert position
            (prevId, nextId) = _findInsertPosition(_troveManager, _NICR, prevId, nextId);
        }

        node.exists = true;

        if (prevId == address(0) && nextId == address(0)) {
            // Insert as head and tail
            data.head = _id;
            data.tail = _id;
        } else if (prevId == address(0)) {
            // Insert before `prevId` as the head
            address head = data.head;
            node.nextId = head;
            data.nodes[head].prevId = _id;
            data.head = _id;
        } else if (nextId == address(0)) {
            // Insert after `nextId` as the tail
            address tail = data.tail;
            node.prevId = tail;
            data.nodes[tail].nextId = _id;
            data.tail = _id;
        } else {
            // Insert at insert position between `prevId` and `nextId`
            node.nextId = nextId;
            node.prevId = prevId;
            data.nodes[prevId].nextId = _id;
            data.nodes[nextId].prevId = _id;
        }

        data.size = data.size + 1;
        emit NodeAdded(_id, _NICR);
    }

    function remove(address _id) external {
        _requireCallerIsTroveManager(troveManager);
        _remove(data.nodes[_id], _id);
    }

    /*
     * @dev Remove a node from the list
     * @param _id Node's id
     */
    function _remove(Node storage node, address _id) internal {
        // List must contain the node
        require(node.exists, "SortedTroves: List does not contain the id");

        if (data.size > 1) {
            // List contains more than a single node
            if (_id == data.head) {
                // The removed node is the head
                // Set head to next node
                address head = node.nextId;
                data.head = head;
                // Set prev pointer of new head to null
                data.nodes[head].prevId = address(0);
            } else if (_id == data.tail) {
                address tail = node.prevId;
                // The removed node is the tail
                // Set tail to previous node
                data.tail = tail;
                // Set next pointer of new tail to null
                data.nodes[tail].nextId = address(0);
            } else {
                address prevId = node.prevId;
                address nextId = node.nextId;
                // The removed node is neither the head nor the tail
                // Set next pointer of previous node to the next node
                data.nodes[prevId].nextId = nextId;
                // Set prev pointer of next node to the previous node
                data.nodes[nextId].prevId = prevId;
            }
        } else {
            // List contains a single node
            // Set the head and tail to null
            data.head = address(0);
            data.tail = address(0);
        }

        delete data.nodes[_id];
        data.size = data.size - 1;
        emit NodeRemoved(_id);
    }

    /*
     * @dev Re-insert the node at a new position, based on its new NICR
     * @param _id Node's id
     * @param _newNICR Node's new NICR
     * @param _prevId Id of previous node for the new insert position
     * @param _nextId Id of next node for the new insert position
     */
    function reInsert(address _id, uint256 _newNICR, address _prevId, address _nextId) external {
        ITroveManager troveManagerCached = troveManager;

        _requireCallerIsTroveManager(troveManagerCached);

        Node storage node = data.nodes[_id];

        // Remove node from the list
        _remove(node, _id);

        _insert(node, troveManagerCached, _id, _newNICR, _prevId, _nextId);
    }

    /*
     * @dev Checks if the list contains a node
     */
    function contains(address _id) public view returns (bool) {
        return data.nodes[_id].exists;
    }

    /*
     * @dev Checks if the list is empty
     */
    function isEmpty() public view returns (bool) {
        return data.size == 0;
    }

    /*
     * @dev Returns the current size of the list
     */
    function getSize() external view returns (uint256) {
        return data.size;
    }

    /*
     * @dev Returns the first node in the list (node with the largest NICR)
     */
    function getFirst() external view returns (address) {
        return data.head;
    }

    /*
     * @dev Returns the last node in the list (node with the smallest NICR)
     */
    function getLast() external view returns (address) {
        return data.tail;
    }

    /*
     * @dev Returns the next node (with a smaller NICR) in the list for a given node
     * @param _id Node's id
     */
    function getNext(address _id) external view returns (address) {
        return data.nodes[_id].nextId;
    }

    /*
     * @dev Returns the previous node (with a larger NICR) in the list for a given node
     * @param _id Node's id
     */
    function getPrev(address _id) external view returns (address) {
        return data.nodes[_id].prevId;
    }

    /*
     * @dev Check if a pair of nodes is a valid insertion point for a new node with the given NICR
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function validInsertPosition(uint256 _NICR, address _prevId, address _nextId) external view returns (bool) {
        return _validInsertPosition(troveManager, _NICR, _prevId, _nextId);
    }

    function _validInsertPosition(
        ITroveManager _troveManager,
        uint256 _NICR,
        address _prevId,
        address _nextId
    ) internal view returns (bool) {
        if (_prevId == address(0) && _nextId == address(0)) {
            // `(null, null)` is a valid insert position if the list is empty
            return isEmpty();
        } else if (_prevId == address(0)) {
            // `(null, _nextId)` is a valid insert position if `_nextId` is the head of the list
            return data.head == _nextId && _NICR >= _troveManager.getNominalICR(_nextId);
        } else if (_nextId == address(0)) {
            // `(_prevId, null)` is a valid insert position if `_prevId` is the tail of the list
            return data.tail == _prevId && _NICR <= _troveManager.getNominalICR(_prevId);
        } else {
            // `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_NICR` falls between the two nodes' NICRs
            return
                data.nodes[_prevId].nextId == _nextId &&
                _troveManager.getNominalICR(_prevId) >= _NICR &&
                _NICR >= _troveManager.getNominalICR(_nextId);
        }
    }

    /*
     * @dev Descend the list (larger NICRs to smaller NICRs) to find a valid insert position
     * @param _troveManager TroveManager contract, passed in as param to save SLOAD’s
     * @param _NICR Node's NICR
     * @param _startId Id of node to start descending the list from
     */
    function _descendList(
        ITroveManager _troveManager,
        uint256 _NICR,
        address _startId
    ) internal view returns (address, address) {
        // If `_startId` is the head, check if the insert position is before the head
        if (data.head == _startId && _NICR >= _troveManager.getNominalICR(_startId)) {
            return (address(0), _startId);
        }

        address prevId = _startId;
        address nextId = data.nodes[prevId].nextId;

        // Descend the list until we reach the end or until we find a valid insert position
        while (prevId != address(0) && !_validInsertPosition(_troveManager, _NICR, prevId, nextId)) {
            prevId = data.nodes[prevId].nextId;
            nextId = data.nodes[prevId].nextId;
        }

        return (prevId, nextId);
    }

    /*
     * @dev Ascend the list (smaller NICRs to larger NICRs) to find a valid insert position
     * @param _troveManager TroveManager contract, passed in as param to save SLOAD’s
     * @param _NICR Node's NICR
     * @param _startId Id of node to start ascending the list from
     */
    function _ascendList(
        ITroveManager _troveManager,
        uint256 _NICR,
        address _startId
    ) internal view returns (address, address) {
        // If `_startId` is the tail, check if the insert position is after the tail
        if (data.tail == _startId && _NICR <= _troveManager.getNominalICR(_startId)) {
            return (_startId, address(0));
        }

        address nextId = _startId;
        address prevId = data.nodes[nextId].prevId;

        // Ascend the list until we reach the end or until we find a valid insertion point
        while (nextId != address(0) && !_validInsertPosition(_troveManager, _NICR, prevId, nextId)) {
            nextId = data.nodes[nextId].prevId;
            prevId = data.nodes[nextId].prevId;
        }

        return (prevId, nextId);
    }

    /*
     * @dev Find the insert position for a new node with the given NICR
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function findInsertPosition(
        uint256 _NICR,
        address _prevId,
        address _nextId
    ) external view returns (address, address) {
        return _findInsertPosition(troveManager, _NICR, _prevId, _nextId);
    }

    function _findInsertPosition(
        ITroveManager _troveManager,
        uint256 _NICR,
        address _prevId,
        address _nextId
    ) internal view returns (address, address) {
        address prevId = _prevId;
        address nextId = _nextId;

        if (prevId != address(0)) {
            if (!contains(prevId) || _NICR > _troveManager.getNominalICR(prevId)) {
                // `prevId` does not exist anymore or now has a smaller NICR than the given NICR
                prevId = address(0);
            }
        }

        if (nextId != address(0)) {
            if (!contains(nextId) || _NICR < _troveManager.getNominalICR(nextId)) {
                // `nextId` does not exist anymore or now has a larger NICR than the given NICR
                nextId = address(0);
            }
        }

        if (prevId == address(0) && nextId == address(0)) {
            // No hint - descend list starting from head
            return _descendList(_troveManager, _NICR, data.head);
        } else if (prevId == address(0)) {
            // No `prevId` for hint - ascend list starting from `nextId`
            return _ascendList(_troveManager, _NICR, nextId);
        } else if (nextId == address(0)) {
            // No `nextId` for hint - descend list starting from `prevId`
            return _descendList(_troveManager, _NICR, prevId);
        } else {
            // Descend list starting from `prevId`
            return _descendList(_troveManager, _NICR, prevId);
        }
    }

    function _requireCallerIsTroveManager(ITroveManager _troveManager) internal view {
        require(msg.sender == address(_troveManager), "SortedTroves: Caller is not the TroveManager");
    }
}