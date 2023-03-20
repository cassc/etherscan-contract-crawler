// contracts/Stage.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum Stage {
    None,
    CollectionPeriod,
    ObservationPeriod,
    OperatingPeriod,
    Final
}

/**
 * @title Stages
 * @dev Implement finite state machines is used to manage business running in different Stages.
 */
contract Stages {

    uint256 public immutable startTime;

    uint256 public immutable collectionPeriodDuration;

    uint256 public immutable observationPeriodDuration;

    uint256 public immutable contractDuraction;

    uint32 public immutable observationDurationInWeeks;

    uint32 public immutable contractDurationInWeeks;

    constructor(uint256 startTime_, uint256 raiseDuration_, uint256 internshipDuration_, uint256 contractDuraction_) {
        // require(startTime_ > block.timestamp, "Stages: invalid start time");
        startTime = startTime_;
        collectionPeriodDuration = raiseDuration_;
        observationPeriodDuration = internshipDuration_;
        contractDuraction = contractDuraction_;
        require((raiseDuration_ + internshipDuration_) < contractDuraction_, "Stages: invalid duration");
        observationDurationInWeeks = uint32(internshipDuration_ / 1 weeks);
        contractDurationInWeeks = uint32(contractDuraction_ / 1 weeks);
    }

    /**
     * @dev Modifier that checks that a stage has valid.
     */
    modifier atStage(Stage _stage) {
        require(_currentStage() == _stage, "Stages: not the stage");
        _;
    }

    /**
     * @dev Modifier that checks that a stage has passed.
     */
    modifier afterStage(Stage _stage) {
        require(_currentStage() > _stage, "Stages: not the right stage");
        _;
    }

    function _currentStage() internal view returns(Stage) {
        uint256 ts = block.timestamp;
        return _stageOf(ts);
    }

    function _stageOf(uint256 ts) internal view returns(Stage) {
        if (ts < startTime) {
            return Stage.None;
        } else if (ts < (startTime + collectionPeriodDuration)) {
            return Stage.CollectionPeriod;
        } else if (ts < (startTime + collectionPeriodDuration + observationPeriodDuration)) {
            return Stage.ObservationPeriod;
        }  else if (ts < (startTime + collectionPeriodDuration + contractDuraction)) {
            return Stage.OperatingPeriod;
        } else {
            return Stage.Final;
        }
    }

    /**
     * @dev Current stage is obtained by the block time calculation.
     */
    function currentStage() external view returns(Stage) {
        return _currentStage();
    }

    function getTimePoints() external view returns(uint256 _now, uint256 _startTime, 
                uint256 _collectionPeriodDuration, uint256 _observationPeriodDuration, uint256 _contractDuraction) {
        _now = block.timestamp;
        _startTime = startTime;
        _collectionPeriodDuration = collectionPeriodDuration;
        _observationPeriodDuration = observationPeriodDuration;
        _contractDuraction = contractDuraction;
    }

    function firstDayOfObservation() public view returns(uint256 day) {
        day = startTime + collectionPeriodDuration;
    }
}