// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

abstract contract TimelockAccess {
    address public timelock;

    modifier onlyTimelock() {
        require(msg.sender == timelock, "Must call from Timelock");
        _;
    }
}