// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract ICaskJobQueue is Initializable {

    function __ICaskJobQueue_init() internal onlyInitializing {
        __ICaskJobQueue_init_unchained();
    }

    function __ICaskJobQueue_init_unchained() internal onlyInitializing {
    }


    function processWorkUnit(uint8 _queueId, bytes32 _workUnit) virtual internal;

    function requeueWorkUnit(uint8 _queueId, bytes32 _workUnit) virtual internal;

    function scheduleWorkUnit(uint8 _queueId, bytes32 _workUnit, uint32 _processAt) virtual internal;

    function queueItem(uint8 _queueId, uint32 _bucket, uint256 _idx) virtual external view returns(bytes32);

    function queueSize(uint8 _queueId, uint32 _bucket) virtual external view returns(uint256);

    function queuePosition(uint8 _queueId) virtual external view returns(uint32);

    function setQueuePosition(uint8 _queueId, uint32 _timestamp) virtual external;

    function setQueueBucketSize(uint32 _queueBucketSize) virtual external;

    function setMaxQueueAge(uint32 _maxQueueAge) virtual external;


    event WorkUnitProcessed(uint8 queueId, bytes32 workUnit);

    event WorkUnitQueued(uint8 queueId, bytes32 workUnit, uint32 processAt);

    /** @dev Emitted when a queue run is finished */
    event QueueRunReport(uint256 limit, uint256 jobsProcessed, uint256 depth, uint8 queueId,
        uint256 queueRemaining, uint32 currentBucket);

}