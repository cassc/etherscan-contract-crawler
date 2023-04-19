// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/governance/TimelockController.sol";

/**************************************************
 *                 Splitter
 **************************************************/

/**
 * Methods in this contract assumes all interactions with gauges and bribes are safe
 * and that the anti-bricking logics are all already processed by voterProxy
 */

contract MagicFoxTimelock is TimelockController {
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {}
}