// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IAzimuth {
    function owner() external returns (address);
    function isSpawnProxy(uint32, address) external returns (bool);
    function hasBeenLinked(uint32) external returns (bool);
    function getPrefix(uint32) external returns (uint16);
    function getOwner(uint32) view external returns (address);
    function canTransfer(uint32, address) view external returns (bool);
    function isOwner(uint32, address) view external returns (bool);
    function getKeyRevisionNumber(uint32 _point) view external returns(uint32);
    function getSpawnCount(uint32 _point) view external returns(uint32);
}