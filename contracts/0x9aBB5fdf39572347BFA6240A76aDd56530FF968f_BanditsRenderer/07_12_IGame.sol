// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGame {
    function health(uint tokenId) external view returns (uint);
}