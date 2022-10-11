// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

abstract contract Queue {
    struct QueueManager {
        uint128 front;
        uint128 back;
    }
    struct QueueItem {
        uint128 next; // The next item to be claimed in the queue. If this is the last item (at back of queue), next should be 0
        uint128 previous; // The previous item in the queue. If this is the first item (at the front of the queue), previous should be 0
        bytes32 id; // An unique identifier for the queue item. This will link the add to queue and withdrawal functions.
        bool isUnclaimed; // Set to true when enqueuing. We can delete the struct when dequeueing, saving some gas.
    }

    // Cause ID => queue manager
    mapping(uint256 => QueueManager) private queueManagers;

    // Queue is operating in reverse and simulates an array with a mapping for gas reasons. It's an implementation of a doubly linked list.
    // [(front) 1][2][(back) 3] (add item) => [(front) 1][2][3][(back) 4]
    // [(front) 1][2][(back) 3] (remove item) => [(front) 2][(back) 3]
    // keccak(causeID, index) => queue item
    mapping(bytes32 => QueueItem) private queueItems;

    /// @notice Adds a new item to the cause queue
    /// @dev _id should not be reused
    /// @param _causeId  The cause to queue an item for
    /// @param _id  The unique ID to use when linking enqueue and withdrawal transactions
    function enqueue(uint256 _causeId, bytes32 _id) internal {
        uint128 currentHead = getFront(_causeId);
        uint128 currentTail = getBack(_causeId);
        uint128 newTail = currentTail + 1;

        if (currentHead == 0){
            currentHead = newTail;
        }

        queueItems[keccak256(abi.encode(_causeId, newTail))] = QueueItem({
            next: 0,
            previous: currentTail,
            id: _id,
            isUnclaimed: true
        });

        if (currentTail != 0) {
            QueueItem memory item = getQueueItem(_causeId, currentTail);
            uint128 prev = item.previous;
            bytes32 id = item.id;
            
            queueItems[keccak256(abi.encode(_causeId, currentTail))] = QueueItem({
                next: newTail,
                previous: prev,
                id: id,
                isUnclaimed: true
            });
        }

        queueManagers[_causeId] = QueueManager({
            front: currentHead,
            back: newTail
        });
    }

    /// @notice Removes an item from the queue
    /// @param _causeId  the cause to dequeue an item for
    function dequeue(uint256 _causeId) internal {
        _removeFromQueue(_causeId, getFront(_causeId));
    }

    /// @notice Removes an arbitrarily placed item from the queue
    /// @param _causeId  the cause to dequeue an item for
    /// @param _index  The index of the item to dequeue. This should be the queue front, unless it's being used to remove an arbitrarily located item from the queue (ie from the middle)
    function dequeue(uint256 _causeId, uint128 _index) internal {
        _removeFromQueue(_causeId, _index);
    }

    /// @notice Removes an item from the cause queue
    /// @param _causeId  the cause to dequeue an item for
    /// @param _index  The index of the item to dequeue. This should be the queue front, unless it's being used to remove an arbitrarily located item from the queue (ie from the middle)
    function _removeFromQueue(uint256 _causeId, uint128 _index) private {
        uint128 currentHead = getFront(_causeId);
        uint128 currentTail = getBack(_causeId);

        bytes32 id = keccak256(abi.encode(_causeId, _index));

        QueueItem memory item = getQueueItem(_causeId, _index);
        uint128 next = item.next;
        uint128 previous = item.previous;
    
        QueueManager storage manager = queueManagers[_causeId];
        uint128 newPrevious = next; uint128 newNext = previous;
        if (_index == currentHead){
            newPrevious = 0;
            manager.front = next;
        }
        if(_index == currentTail){
            newNext = 0;
            manager.back = previous;
        }

        queueItems[keccak256(abi.encode(_causeId, next))].previous = newPrevious;
        queueItems[keccak256(abi.encode(_causeId, previous))].next = newNext;
    
        delete queueItems[id];
    }

    /// @notice Returns the current ID at the front of the queue
    function getFront(uint256 _causeId)
        internal
        view
        returns (uint128 queueFront)
    {
        QueueManager memory manager = queueManagers[_causeId];
        queueFront = manager.front;
    }

    /// @notice Returns the current ID at the back of the queue
    function getBack(uint256 _causeId)
        internal
        view
        returns (uint128 queueBack)
    {
        QueueManager memory manager = queueManagers[_causeId];
        queueBack = manager.back;
    }

    /// @notice Returns the queue item at a given index
    function getQueueItem(uint256 _causeId, uint128 _index)
        internal
        view
        returns (QueueItem memory item)
    {
        item = queueItems[keccak256(abi.encode(_causeId, _index))];
    }
}