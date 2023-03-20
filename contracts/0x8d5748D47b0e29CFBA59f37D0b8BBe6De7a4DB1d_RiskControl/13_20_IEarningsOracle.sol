// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEarningsOracle {
    function lastRound() external view returns (uint256, uint256);

    function getRound(uint256 day) external view returns (uint256);
}