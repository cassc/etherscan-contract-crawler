pragma solidity ^0.5.16;

import "../Timelock.sol";

contract Nolock is Timelock {

    function gracePeriod() public pure returns (uint) { return 10 minutes; }

    function minimumDelay() public pure returns (uint) { return 1 seconds; }

    function maximumDelay() public pure returns (uint) { return 100000 days; }

    constructor(address admin_, uint delay_) public Timelock(admin_, delay_) {}
}