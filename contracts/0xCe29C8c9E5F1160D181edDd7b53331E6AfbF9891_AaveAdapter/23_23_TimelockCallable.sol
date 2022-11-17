// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

abstract contract TimelockCallable {
    address public TIMELOCK_ADDRESS;

    event SetTimeLock(address newTimelock);

    constructor(address _timelock) {
        TIMELOCK_ADDRESS = _timelock;
    }

    modifier onlyTimelock() {
        require(TIMELOCK_ADDRESS == msg.sender, "Caller is not the timelock.");
        _;
    }

    function setTimelock(address newTimelock) external onlyTimelock {
        require(newTimelock != address(0));
        TIMELOCK_ADDRESS = newTimelock;
        emit SetTimeLock(newTimelock);
    }
}