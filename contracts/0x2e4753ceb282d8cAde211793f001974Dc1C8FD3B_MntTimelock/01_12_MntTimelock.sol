// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";

contract MntTimelock is TimelockControllerUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) external initializer {
        __TimelockController_init(minDelay, proposers, executors);
    }
}