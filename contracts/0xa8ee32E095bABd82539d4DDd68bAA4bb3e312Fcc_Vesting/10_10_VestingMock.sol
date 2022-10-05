// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../Vesting.sol";

contract VestingMock is Vesting {
    uint32 public time;

    constructor(IERC20 token) Vesting(token) {}

    function setMockTime(uint32 time_) public returns (uint32) {
        time = time_;
        return time;
    }

    function getTime() internal view override returns (uint32) {
        return time;
    }
}