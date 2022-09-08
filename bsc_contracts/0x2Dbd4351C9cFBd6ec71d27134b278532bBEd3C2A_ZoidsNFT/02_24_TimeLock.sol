// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract TimeLock is Ownable {
    uint256 private timeLock;

    constructor() public {
        timeLock = 0;
    }

    modifier notLocked() {
        require(timeLock <= block.timestamp, "Time lock is on");
        _;
    }

    function setTimeLock(uint256 _time) public onlyOwner {
        timeLock = _time;
    }

    function getTimeLock() public view returns (uint256) {
        return timeLock;
    }
}