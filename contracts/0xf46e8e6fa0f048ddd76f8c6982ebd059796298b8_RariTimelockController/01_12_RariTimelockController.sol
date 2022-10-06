// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import  "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";

contract RariTimelockController is TimelockControllerUpgradeable {
    
    function __RariTimelockController_init(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) external initializer {
        __TimelockController_init(minDelay, proposers, executors);
    }
}