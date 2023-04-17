// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../Adminable.sol';

abstract contract Timed is Adminable {
    uint256 public startTime;
    uint256 public duration;
    uint256 public registerTime;
    uint256 public registerDuration;
    // FCFS starts from: end - fcfsDuration
    uint256 public fcfsDuration;

    event StartChanged(uint256 time);
    event DurationChanged(uint256 duration);
    event RegisterTimeChanged(uint256 time);
    event RegisterDurationChanged(uint256 duration);
    event FCFSDurationChanged(uint256 duration);

    constructor(uint256[] memory timeline) {
        require(
            timeline.length == 5,
            'Timed: Timeline must have [startTime, duration, registerTime, registerDuration, fcfsDuration]'
        );
        startTime = timeline[0];
        duration = timeline[1];
        setTimeline(timeline[2], timeline[3], timeline[4]);
    }

    modifier ongoingSale() {
        require(isLive(), 'Sale: Not live');
        _;
    }

    function isLive() public view returns (bool) {
        return block.timestamp > startTime && block.timestamp < getEndTime();
    }

    function isFcfsTime() public view returns (bool) {
        return block.timestamp + fcfsDuration > getEndTime() && block.timestamp < getEndTime();
    }

    function getEndTime() public view returns (uint256) {
        return startTime + duration;
    }

    function setStartTime(uint256 newTime) public onlyOwnerOrAdmin {
        require(newTime > registerTime, 'Sale: start time must be after the register time');
        startTime = newTime;
        emit StartChanged(startTime);
    }

    function setDuration(uint256 newDuration) public onlyOwnerOrAdmin {
        duration = newDuration;
        emit DurationChanged(duration);
    }

    function setRegisterTime(uint256 newTime) public onlyOwnerOrAdmin {
        require(newTime < startTime, 'Sale: register time must be before the start time');
        registerTime = newTime;
        emit RegisterTimeChanged(registerTime);
    }

    function setRegisterDuration(uint256 newDuration) public onlyOwnerOrAdmin {
        require(registerTime + newDuration < startTime, 'Sale: register end must be before the start time');
        registerDuration = newDuration;
        emit RegisterDurationChanged(registerDuration);
    }

    function setFCFSDuration(uint256 newDuration) public onlyOwnerOrAdmin {
        fcfsDuration = newDuration;
        emit FCFSDurationChanged(duration);
    }

    function setTimeline(
        uint256 _registerTime,
        uint256 _registerDuration,
        uint256 _fcfsDuration
    ) public onlyOwnerOrAdmin {
        setRegisterTime(_registerTime);
        setRegisterDuration(_registerDuration);
        setFCFSDuration(_fcfsDuration);
    }
}