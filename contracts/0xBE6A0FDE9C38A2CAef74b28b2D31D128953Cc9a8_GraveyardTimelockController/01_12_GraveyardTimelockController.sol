pragma solidity ^0.8.17;

import "TimelockController.sol";

contract GraveyardTimelockController is TimelockController {
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors, address admin) TimelockController(minDelay, proposers, executors, admin) {}
}