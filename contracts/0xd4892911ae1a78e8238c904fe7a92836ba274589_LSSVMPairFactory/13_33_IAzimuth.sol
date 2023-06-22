// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IAzimuth {
    function owner() view external returns (address);
    function getSpawnCount(uint32 _point) view external returns(uint32);
    function getSpawnProxy(uint32 _point) view external returns(address);
    function getPointSize(uint32) external pure returns (Size);
    enum Size
    {
        Galaxy, // = 0
        Star,   // = 1
        Planet  // = 2
    }
}