// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IETHLeverage {
    function loanFallback(uint256 loanAmt, uint256 feeAmt) external;
}