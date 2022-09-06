// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "TimelockController.sol";

contract Timelock is TimelockController {
    constructor(address[] memory proposers, address[] memory executors)
        TimelockController(86400 * 2, proposers, executors)
    {}
}