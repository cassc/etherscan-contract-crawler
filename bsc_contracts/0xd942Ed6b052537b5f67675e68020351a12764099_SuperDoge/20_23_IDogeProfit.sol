// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


interface IDogeProfit {
    struct Process {
        uint64 income;
        address from;
        address to;
        uint64 balanceFromBefore;
        uint64 balanceToBefore;
        uint64 balanceFromNow;
        uint64 balanceToNow;
    }
    function processTransfer(Process memory) external;
}