// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// chainlink oracles interface
interface IAggregatorV3 {
    function latestAnswer() external view returns (int256);
}