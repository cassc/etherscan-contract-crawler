// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPump {
    event Pumped(address indexed from, uint[] tokenIds);
    event Drained(address indexed from, uint[] tokenIds);

    function pump(uint[] memory ids) external;
    function drain() external;
    function getPumpTier() external view returns (uint);
    function getNextPumpTier() external view returns (uint);

    function version() external view returns (string memory);
}