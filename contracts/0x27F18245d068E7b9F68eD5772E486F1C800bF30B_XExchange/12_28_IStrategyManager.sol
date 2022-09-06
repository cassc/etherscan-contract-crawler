// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategyManager {
    event Added(address strategy);
    event Removed(address strategy);

    function add(address strategy) external;

    function remove(address strategy) external;

    function isValid(address strategy) external view returns (bool valid);
}