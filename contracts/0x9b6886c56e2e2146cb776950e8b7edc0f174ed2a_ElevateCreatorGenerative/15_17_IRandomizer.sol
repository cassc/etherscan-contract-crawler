// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRandomizer {
    function getRandomValue() external view returns (uint256);
}