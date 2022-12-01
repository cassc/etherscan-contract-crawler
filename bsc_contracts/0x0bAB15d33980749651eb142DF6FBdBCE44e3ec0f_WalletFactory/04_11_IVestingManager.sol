// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IVestingManager {
    function start() external view returns (uint64);
    function duration() external view returns (uint64);
    function setStart(uint64) external;
    function setDuration(uint64) external;
}