// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRegistry {
    function randomService(uint256 key) external returns (IRandomService);
}

interface IRandomService {
    function random() external returns (uint256);
}