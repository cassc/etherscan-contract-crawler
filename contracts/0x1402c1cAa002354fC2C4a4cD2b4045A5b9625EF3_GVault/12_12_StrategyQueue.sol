// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;

//  ________  ________  ________
//  |\   ____\|\   __  \|\   __  \
//  \ \  \___|\ \  \|\  \ \  \|\  \
//   \ \  \  __\ \   _  _\ \  \\\  \
//    \ \  \|\  \ \  \\  \\ \  \\\  \
//     \ \_______\ \__\\ _\\ \_______\
//      \|_______|\|__|\|__|\|_______|

// gro protocol: https://github.com/groLabs/GSquared

/// @title StrategyQueue
/// @notice StrategyQueue - logic for handling ordering of vault strategies
///     ---------    ---------    ---------
///     | Strat |    | Strat |    | Strat |
///     |  ---  |    |  ---  |    |  ---  |
/// 0<--|  prev-|<---|  prev-|<---|  prev-|
///     |  next-|--->|  next-|--->|  next-|-->0
///     ---------    ---------    ---------
///       Head                      Tail
contract StrategyQueue {
    /*//////////////////////////////////////////////////////////////
                    STORAGE VARIABLES & TYPES
    //////////////////////////////////////////////////////////////*/

    // node in queue
    struct Strategy {
        uint48 next;
        uint48 prev;
        address strategy;
    }

    // Information regarding queue
    struct Queue {
        uint48 head;
        uint48 tail;
        uint48 totalNodes;
        uint48 nextAvailableNode;
    }

    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MAXIMUM_STRATEGIES = 5;
    address internal constant ZERO_ADDRESS = address(0);
    uint48 internal constant EMPTY_NODE = 0;

    mapping(address => uint256) public strategyId;
    mapping(uint256 => Strategy) internal nodes;

    Queue internal strategyQueue;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogStrategyRemoved(address indexed strategy, uint256 indexed id);
    event LogStrategyAdded(
        address indexed strategy,
        uint256 indexed id,
        uint256 pos
    );
    event LogNewQueueLink(uint256 indexed id, uint256 next);
    event LogNewQueueHead(uint256 indexed id);
    event LogNewQueueTail(uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                            ERRORS HANDLING
    //////////////////////////////////////////////////////////////*/

    error NoIdEntry(uint256 id);
    error StrategyNotMoved(uint256 errorNo);
    // 1 - no move specified
    // 2 - strategy cant be moved further up/down the queue
    // 3 - strategy moved to its own position
    error NoStrategyEntry(address strategy);
    error StrategyExists(address strategy);
    error MaxStrategyExceeded();

    /*//////////////////////////////////////////////////////////////
                               GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Get strategy at position i of withdrawal queue
    /// @param i position in withdrawal queue
    /// @return strategy strategy at position i
    function withdrawalQueueAt(uint256 i)
        external
        view
        returns (address strategy)
    {
        if (i == 0 || i == strategyQueue.totalNodes - 1) {
            strategy = i == 0
                ? nodes[strategyQueue.head].strategy
                : nodes[strategyQueue.tail].strategy;
        } else {
            uint256 index = strategyQueue.head;
            for (uint256 j; j <= i; j++) {
                if (j == i) return nodes[index].strategy;
                index = nodes[index].next;
            }
        }
    }

    /// @notice Get the entire withdrawal queue
    /// @return queue list of all strategy ids in order of withdrawal priority
    function fullWithdrawalQueue()
        internal
        view
        returns (uint256[MAXIMUM_STRATEGIES] memory queue)
    {
        uint256 index = strategyQueue.head;
        uint256 _totalNodes = strategyQueue.totalNodes;
        queue[0] = index;
        for (uint256 i = 1; i < _totalNodes; ++i) {
            index = nodes[index].next;
            queue[i] = index;
        }
    }

    /// @notice Get position of strategy in withdrawal queue
    /// @param _strategy address of strategy
    /// @return returns position of strategy in withdrawal queue
    function getStrategyPositions(address _strategy)
        public
        view
        returns (uint256)
    {
        uint48 index = strategyQueue.head;
        uint48 _totalNodes = strategyQueue.totalNodes;
        for (uint48 i = 0; i <= _totalNodes; ++i) {
            if (_strategy == nodes[index].strategy) {
                return i;
            }
            index = nodes[index].next;
        }
        revert NoStrategyEntry(_strategy);
    }

    /*//////////////////////////////////////////////////////////////
                          QUEUE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Add a strategy to the end of the queue
    /// @param _strategy address of strategy to add
    /// @dev creates a new node which is inserted at the end of the
    ///     strategy queue. the strategy is assigned an id and is
    ///     linked to the previous tail. Note that this ID isnt
    ///        necessarily the same as the position in the withdrawal queue
    function _push(address _strategy) internal returns (uint256) {
        if (strategyId[_strategy] > 0) revert StrategyExists(_strategy);
        uint48 nodeId = _createNode(_strategy);
        return uint256(nodeId);
    }

    /// @notice Remove strategy from queue
    /// @param _strategy strategy to remove
    /// @dev removes a node and links the nodes neighbours
    function _pop(address _strategy) internal {
        uint256 id = strategyId[_strategy];
        if (id == 0) revert NoStrategyEntry(_strategy);
        Strategy storage removeNode = nodes[uint48(id)];
        address strategy = removeNode.strategy;
        if (strategy == ZERO_ADDRESS) revert NoIdEntry(id);
        _link(removeNode.prev, removeNode.next);
        strategyId[_strategy] = 0;
        emit LogStrategyRemoved(strategy, id);
        delete nodes[uint48(id)];
        strategyQueue.totalNodes -= 1;
    }

    /// @notice move a strategy to a new position in the queue
    /// @param _id id of strategy to move
    /// @param _steps number of steps to move the strategy
    /// @param _back move towards tail (true) or head (false)
    /// @dev Moves a strategy a given number of steps. If the number
    ///        of steps exceeds the position of the head/tail, the
    ///        strategy will take the place of the current head/tail
    function move(
        uint48 _id,
        uint48 _steps,
        bool _back
    ) internal {
        Strategy storage oldPos = nodes[_id];
        if (_steps == 0) revert StrategyNotMoved(1);
        if (oldPos.strategy == ZERO_ADDRESS) revert NoIdEntry(_id);
        uint48 _newPos = !_back ? oldPos.prev : oldPos.next;
        if (_newPos == 0) revert StrategyNotMoved(2);

        for (uint256 i = 1; i < _steps; ++i) {
            _newPos = !_back ? nodes[_newPos].prev : nodes[_newPos].next;
            if (_newPos == 0) {
                _newPos = !_back ? strategyQueue.head : strategyQueue.tail;
                break;
            }
        }
        if (_newPos == _id) revert StrategyNotMoved(3);
        Strategy memory newPos = nodes[_newPos];
        _link(oldPos.prev, oldPos.next);
        if (!_back) {
            _link(newPos.prev, _id);
            _link(_id, _newPos);
        } else {
            _link(_id, newPos.next);
            _link(_newPos, _id);
        }
    }

    /// @notice Create a new node to be inserted at the tail of the queue
    /// @param _strategy address of strategy to add
    /// @return id of strategy
    function _createNode(address _strategy) internal returns (uint48) {
        uint48 _totalNodes = strategyQueue.totalNodes;
        if (_totalNodes >= MAXIMUM_STRATEGIES) revert MaxStrategyExceeded();
        strategyQueue.nextAvailableNode += 1;
        strategyQueue.totalNodes = _totalNodes + 1;
        uint48 newId = uint48(strategyQueue.nextAvailableNode);
        strategyId[_strategy] = newId;

        uint48 _tail = strategyQueue.tail;
        Strategy memory node = Strategy(EMPTY_NODE, _tail, _strategy);

        _link(_tail, newId);
        _setTail(newId);
        nodes[newId] = node;

        emit LogStrategyAdded(_strategy, newId, _totalNodes + 1);

        return newId;
    }

    /// @notice Set the head of the queue
    /// @param _id Id of the strategy to set the head to
    function _setHead(uint256 _id) internal {
        strategyQueue.head = uint48(_id);
        emit LogNewQueueHead(_id);
    }

    /// @notice Set the tail of the queue
    /// @param _id Id of the strategy to set the tail to
    function _setTail(uint256 _id) internal {
        strategyQueue.tail = uint48(_id);
        emit LogNewQueueTail(_id);
    }

    /// @notice Link two nodes
    /// @param _prevId id of previous node
    /// @param _nextId id of next node
    function _link(uint48 _prevId, uint48 _nextId) internal {
        if (_prevId == EMPTY_NODE) {
            _setHead(_nextId);
        } else {
            nodes[_prevId].next = _nextId;
        }
        if (_nextId == EMPTY_NODE) {
            _setTail(_prevId);
        } else {
            nodes[_nextId].prev = _prevId;
        }
        emit LogNewQueueLink(_prevId, _nextId);
    }
}