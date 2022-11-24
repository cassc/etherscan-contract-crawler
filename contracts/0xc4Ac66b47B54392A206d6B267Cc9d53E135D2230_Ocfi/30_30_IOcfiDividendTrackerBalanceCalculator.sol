// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IOcfiDividendTrackerBalanceCalculator {
    function calculateBalance(address account) external view returns (uint256);
}