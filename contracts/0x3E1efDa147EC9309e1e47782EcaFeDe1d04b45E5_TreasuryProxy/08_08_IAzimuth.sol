// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAzimuth {
    function canSpawnAs(uint32, address) view external returns (bool);
    function canTransfer(uint32, address) view external returns (bool);
    function getPrefix(uint32) external pure returns (uint16);
    function getPointSize(uint32) external pure returns (Size);
    function owner() external returns (address);
    function getSpawnCount(uint32) view external returns (uint32);
    enum Size
    {
        Galaxy, // = 0
        Star,   // = 1
        Planet  // = 2
    }
}