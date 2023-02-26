// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IDateTime {
    function getYear(uint timestamp) external pure returns (uint16);
    function getMonth(uint timestamp) external pure returns (uint16);
    function getDay(uint timestamp) external pure returns (uint16);
    function getHour(uint timestamp) external pure returns (uint16);
    function getMinute(uint timestamp) external pure returns (uint16);
    function getSecond(uint timestamp) external pure returns (uint16);
}