// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface OracleWrapper {
    function latestAnswer() external view returns (uint256);
}