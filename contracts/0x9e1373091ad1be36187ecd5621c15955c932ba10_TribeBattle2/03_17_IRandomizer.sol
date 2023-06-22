// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IRandomizer {
    function randomMod(uint256,uint256,uint256) external returns (uint256);
}