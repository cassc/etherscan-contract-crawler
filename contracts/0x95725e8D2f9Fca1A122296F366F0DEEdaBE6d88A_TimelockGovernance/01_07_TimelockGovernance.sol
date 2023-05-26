// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/TimelockController.sol';

contract TimelockGovernance is TimelockController {
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) public TimelockController(minDelay, proposers, executors) {
        /// @dev Deployer renounces its admin role. The contract becomes self managed.
        renounceRole(TIMELOCK_ADMIN_ROLE, msg.sender);
    }
}