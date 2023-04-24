// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISweepingFunds {
    function fundSweep(uint256 price) external;
    function closeFunds(address payable receiver, bool destruct) external;
}