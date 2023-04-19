// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IWKDRaffle {
    function startCycle(uint256 price, uint256 winsPer20) external;
    function isDeprecated(uint256 price, uint256 winsPer20) external view returns(bool);
}