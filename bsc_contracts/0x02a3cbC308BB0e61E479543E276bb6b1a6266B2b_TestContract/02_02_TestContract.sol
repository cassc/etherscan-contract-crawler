//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "./Counters.sol";

contract TestContract {
    using Counters for Counters.Counter;
    Counters.Counter public test;

    function Set() public {
        test.increment();
    }
}